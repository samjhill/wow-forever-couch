#!/usr/bin/env python3
"""Headless WoW chat stand-in for dictation harnesses.

Reads JSONL input events from a FIFO (or stdin) and mirrors Forever chat
behavior enough to validate Esc → Enter → type → [Enter] inject/confirm:

  {"type":"key","key":"esc"}
  {"type":"key","key":"enter"}
  {"type":"type","text":"..."}
  {"type":"set_group","size":0,"raid":false}
  {"type":"quit"}

Writes atomic JSON state to --state (default: config/mock-wow-state.json).

Sticky channel policy matches CouchDictateRoute / resolve_channel.py:
  raid → RAID; party size >= 3 → PARTY; else SAY.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
import time
from pathlib import Path

SLASH_RE = re.compile(
    r"^(?:/(?:say|s)\s+|/(?:party|p)\s+|/(?:raid|r)\s+)(?P<body>.*)$",
    re.IGNORECASE,
)


def sticky_channel(size: int, raid: bool) -> str:
    if raid:
        return "RAID"
    if size >= 3:
        return "PARTY"
    return "SAY"


def atomic_write(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=str(path.parent), prefix=".mock-wow-", suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
            f.write("\n")
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            try:
                os.unlink(tmp)
            except OSError:
                pass


class MockWowChat:
    def __init__(self, state_path: Path) -> None:
        self.state_path = state_path
        self.chat_open = False
        self.draft = ""
        self.channel = "SAY"
        self.group_size = 0
        self.in_raid = False
        self.sent: list[dict] = []
        self.events: list[dict] = []
        self.flush("boot")

    def snapshot(self) -> dict:
        return {
            "ts": time.time(),
            "chat_open": self.chat_open,
            "draft": self.draft,
            "channel": self.channel,
            "group_size": self.group_size,
            "in_raid": self.in_raid,
            "sent": list(self.sent),
            "events": list(self.events[-50:]),
        }

    def flush(self, reason: str) -> None:
        data = self.snapshot()
        data["last_reason"] = reason
        atomic_write(self.state_path, data)

    def note(self, kind: str, **extra) -> None:
        self.events.append({"ts": time.time(), "kind": kind, **extra})

    def apply_sticky(self) -> None:
        self.channel = sticky_channel(self.group_size, self.in_raid)

    def parse_payload(self, text: str) -> tuple[str, str]:
        m = SLASH_RE.match(text)
        if not m:
            return self.channel, text
        raw = text.split(None, 1)[0].lower()
        if raw in {"/say", "/s"}:
            ch = "SAY"
        elif raw in {"/party", "/p"}:
            ch = "PARTY"
        else:
            ch = "RAID"
        return ch, m.group("body")

    def on_esc(self) -> None:
        self.note("esc", chat_open=self.chat_open, draft=self.draft)
        self.chat_open = False
        self.draft = ""
        self.flush("esc")

    def on_enter(self) -> None:
        if not self.chat_open:
            self.apply_sticky()
            self.chat_open = True
            self.draft = ""
            self.note("open_chat", channel=self.channel)
            self.flush("open_chat")
            return
        body = self.draft
        if body.strip() == "":
            self.chat_open = False
            self.note("enter_empty_close")
            self.flush("enter_empty_close")
            return
        channel, text = self.parse_payload(body)
        self.sent.append({"ts": time.time(), "channel": channel, "text": text, "raw": body})
        self.note("send", channel=channel, text=text)
        self.chat_open = False
        self.draft = ""
        self.flush("send")

    def on_type(self, text: str) -> None:
        if not self.chat_open:
            self.note("type_ignored", text=text)
            self.flush("type_ignored")
            return
        self.draft += text
        if self.draft.lstrip().startswith("/"):
            ch, _ = self.parse_payload(self.draft)
            self.channel = ch
        self.note("type", text=text, draft=self.draft, channel=self.channel)
        self.flush("type")

    def handle(self, obj: dict) -> bool:
        t = obj.get("type")
        if t == "quit":
            self.note("quit")
            self.flush("quit")
            return False
        if t == "set_group":
            self.group_size = int(obj.get("size") or 0)
            self.in_raid = bool(obj.get("raid") or False)
            self.apply_sticky()
            self.note(
                "set_group",
                size=self.group_size,
                raid=self.in_raid,
                channel=self.channel,
            )
            self.flush("set_group")
            return True
        if t == "key":
            key = str(obj.get("key") or "").lower()
            if key in {"esc", "escape"}:
                self.on_esc()
            elif key in {"enter", "return"}:
                self.on_enter()
            else:
                self.note("unknown_key", key=key)
                self.flush("unknown_key")
            return True
        if t == "type":
            self.on_type(str(obj.get("text") or ""))
            return True
        self.note("unknown_event", obj=obj)
        self.flush("unknown_event")
        return True


def open_event_source(path: str | None):
    if not path or path == "-":
        return sys.stdin
    p = Path(path)
    if p.exists() and not p.is_fifo():
        p.unlink()
    if not p.exists():
        os.mkfifo(p, 0o600)
    fd = os.open(p, os.O_RDWR)
    return os.fdopen(fd, "r", encoding="utf-8", errors="replace")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--fifo", default=None, help="JSONL FIFO path (default stdin)")
    ap.add_argument("--state", required=True, help="State JSON output path")
    ap.add_argument("--ready-file", default=None, help="Touched when listening")
    args = ap.parse_args()

    mock = MockWowChat(Path(args.state))
    src = open_event_source(args.fifo)
    if args.ready_file:
        Path(args.ready_file).write_text(str(os.getpid()), encoding="utf-8")
    print(
        f"mock-wow-chat listening state={args.state} fifo={args.fifo or 'stdin'}",
        flush=True,
    )

    buf = ""
    try:
        while True:
            chunk = src.read(1)
            if chunk == "":
                time.sleep(0.05)
                continue
            buf += chunk
            while "\n" in buf:
                line, buf = buf.split("\n", 1)
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError as exc:
                    mock.note("bad_json", error=str(exc), line=line[:120])
                    mock.flush("bad_json")
                    continue
                if not mock.handle(obj):
                    return 0
    except KeyboardInterrupt:
        mock.note("interrupt")
        mock.flush("interrupt")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
