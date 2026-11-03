#!/usr/bin/env python3
"""Watch FIFO + Steam Controller left grip + KEY_F20; run dictate or confirm draft."""
from __future__ import annotations

import json
import os
import select
import subprocess
import sys
import threading
import time
from pathlib import Path

try:
    import evdev
    from evdev import ecodes
except ImportError:
    print("evdev required: pip install --user evdev", file=sys.stderr)
    raise

BASE = Path(
    os.environ.get("WOW_FOREVER_COUCH")
    or os.environ.get("WOW_BAZZITE_SETUP")
    or Path(__file__).resolve().parents[1]
)
DICTATE = BASE / "scripts" / "dictate-push-to-talk.sh"
CONFIRM = BASE / "scripts" / "confirm-wow-chat.sh"
FIFO = BASE / "config" / "dictate.trigger"
STATUS = BASE / "config" / "dictate-status.json"
COOLDOWN_S = float(os.environ.get("DICTATE_COOLDOWN", "1.5"))
DRAFT_TTL_S = float(os.environ.get("DICTATE_DRAFT_TTL", "60"))

# Linux BTN_GRIPL / BTN_GRIPR (newer) and fallbacks
GRIPL = getattr(ecodes, "BTN_GRIPL", 548)
GRIPR = getattr(ecodes, "BTN_GRIPR", 549)
GRIP_CODES = {
    GRIPL,
    GRIPR,
    getattr(ecodes, "BTN_GEAR_DOWN", 336),  # sometimes left grip on older maps
}
F20 = getattr(ecodes, "KEY_F20", 190)

_last_fire = 0.0
_lock = threading.Lock()


def log(msg: str) -> None:
    print(f"[dictate-daemon] {msg}", flush=True)


def load_status() -> dict:
    try:
        return json.loads(STATUS.read_text())
    except Exception:  # noqa: BLE001
        return {}


def pending_draft() -> bool:
    """True when a draft is waiting for grip-confirm and has not expired."""
    data = load_status()
    if data.get("state") != "draft":
        return False
    ts = float(data.get("ts") or 0)
    if ts <= 0:
        return False
    age = time.time() - ts
    if age > DRAFT_TTL_S:
        log(f"draft expired ({age:.0f}s > {DRAFT_TTL_S:.0f}s TTL)")
        return False
    return True


def run_script(script: Path, args: list[str] | None = None, env_extra: dict | None = None) -> None:
    env = os.environ.copy()
    if env_extra:
        env.update(env_extra)
    cmd = [str(script)] + (args or [])
    subprocess.Popen(
        cmd,
        env=env,
        cwd=str(BASE),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def fire_dictate(reason: str) -> None:
    env = os.environ.copy()
    # Harness can drop a sidecar env file for one-shot DICTATE_WAV
    env_file = BASE / "config" / "dictate-env"
    if env_file.is_file():
        for line in env_file.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k] = v
        try:
            env_file.unlink()
        except OSError:
            pass
    log(f"dictate: {reason}")
    run_script(DICTATE, env_extra=env)


def fire_confirm(reason: str) -> None:
    log(f"confirm draft: {reason}")
    run_script(CONFIRM, ["confirm"])


def fire_cancel(reason: str) -> None:
    log(f"cancel draft: {reason}")
    run_script(CONFIRM, ["cancel"])


def fire(reason: str, action: str = "auto") -> None:
    """action: auto|dictate|confirm|cancel — auto confirms when a draft is pending."""
    global _last_fire
    with _lock:
        now = time.time()
        if now - _last_fire < COOLDOWN_S:
            log(f"cooldown skip ({reason})")
            return
        _last_fire = now

    if action == "cancel":
        fire_cancel(reason)
        return
    if action == "confirm":
        fire_confirm(reason)
        return
    if action == "dictate":
        fire_dictate(reason)
        return

    # auto: second left-grip / F20 confirms an open draft instead of re-recording
    if pending_draft():
        fire_confirm(reason)
    else:
        fire_dictate(reason)


def ensure_fifo() -> None:
    FIFO.parent.mkdir(parents=True, exist_ok=True)
    if FIFO.exists() and not FIFO.is_fifo():
        FIFO.unlink()
    if not FIFO.exists():
        os.mkfifo(FIFO, 0o600)
    log(f"FIFO ready: {FIFO}")


def open_devices():
    devices = []
    for path in Path("/dev/input").glob("event*"):
        try:
            dev = evdev.InputDevice(path)
        except (OSError, PermissionError):
            continue
        name = (dev.name or "").lower()
        caps = dev.capabilities().get(ecodes.EV_KEY, [])
        want = False
        if "steam controller" in name or "wireless steam controller" in name:
            if GRIP_CODES & set(caps):
                want = True
        if F20 in caps or "keyboard" in name or "steam" in name:
            if F20 in caps or "steam" in name:
                want = True
        if want:
            devices.append(dev)
            log(f"watching {path} ({dev.name})")
    return devices


def fifo_loop() -> None:
    ensure_fifo()
    # O_RDWR avoids block-on-open when no peer; select for readability.
    fd = os.open(FIFO, os.O_RDWR | os.O_NONBLOCK)
    buf = b""
    while True:
        try:
            r, _, _ = select.select([fd], [], [], 1.0)
            if not r:
                continue
            chunk = os.read(fd, 4096)
            if not chunk:
                continue
            buf += chunk
            while b"\n" in buf or buf.strip():
                if b"\n" in buf:
                    line, buf = buf.split(b"\n", 1)
                else:
                    line, buf = buf, b""
                data = line.decode("utf-8", "replace").strip().lower()
                if data in {"", "fire", "dictate", "1", "auto"}:
                    fire("fifo", "auto")
                elif data in {"confirm", "send", "enter"}:
                    fire("fifo:confirm", "confirm")
                elif data in {"cancel", "esc", "discard"}:
                    fire("fifo:cancel", "cancel")
                else:
                    fire(f"fifo:{data[:40]}", "auto")
                if not buf:
                    break
        except Exception as exc:  # noqa: BLE001
            log(f"fifo error: {exc}")
            time.sleep(0.5)


def evdev_loop(devices) -> None:
    if not devices:
        log("no evdev devices matched; FIFO-only mode")
        while True:
            time.sleep(3600)
    mapping = {dev.fd: dev for dev in devices}
    while True:
        try:
            r, _, _ = select.select(list(mapping), [], [], 5.0)
        except (OSError, ValueError):
            time.sleep(1)
            devices = open_devices()
            mapping = {dev.fd: dev for dev in devices}
            continue
        for fd in r:
            dev = mapping.get(fd)
            if not dev:
                continue
            try:
                for event in dev.read():
                    if event.type != ecodes.EV_KEY or event.value != 1:
                        continue
                    if event.code == GRIPR:
                        # Right grip discards an open draft (Esc)
                        if pending_draft():
                            fire(f"gripR-cancel:{dev.name}", "cancel")
                        else:
                            log("right grip ignored (no draft)")
                    elif event.code in GRIP_CODES:
                        fire(f"grip:{dev.name}:{event.code}", "auto")
                    elif event.code == F20:
                        fire(f"F20:{dev.name}", "auto")
            except (OSError, BlockingIOError):
                continue


def main() -> int:
    if not DICTATE.is_file():
        log(f"missing dictate script: {DICTATE}")
        return 2
    if not CONFIRM.is_file():
        log(f"missing confirm script: {CONFIRM}")
        return 2
    ensure_fifo()
    t = threading.Thread(target=fifo_loop, name="fifo", daemon=True)
    t.start()
    devices = open_devices()
    log(f"ready (draft confirm on 2nd grip; TTL={DRAFT_TTL_S:.0f}s)")
    evdev_loop(devices)
    return 0


if __name__ == "__main__":
    sys.exit(main())
