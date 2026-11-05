#!/usr/bin/env python3
"""Watch FIFO + controller dictate binds + Steam Input keyboard key.

Binds (host / Steam Input):
  Steam Controller — left grip (BTN_GRIPL) hold-to-talk; right grip cancel
  Xbox — R3 (BTN_THUMBR) hold-to-talk; Steam Input → Insert (KEY_INSERT)
  Steam keyboard layer — KEY_INSERT (preferred; shown in Steam's picker)
  Legacy — KEY_F20 still accepted if an old layout emits it

Hold-to-talk: key/button down starts capture; release stops and runs Whisper.
"""
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
STOP_FILE = Path(os.environ.get("DICTATE_STOP_FILE", "/tmp/wow-dictate.stop"))
COOLDOWN_S = float(os.environ.get("DICTATE_COOLDOWN", "0.8"))
DRAFT_TTL_S = float(os.environ.get("DICTATE_DRAFT_TTL", "60"))
# While Whisper/inject runs, ignore extra presses. Recording accepts release→stop.
BUSY_STATES = frozenset({"transcribing", "injecting", "busy"})
RECORDING_STATES = frozenset({"recording"})

# Linux BTN_GRIPL / BTN_GRIPR (Steam Controller) and fallbacks
GRIPL = getattr(ecodes, "BTN_GRIPL", 548)
GRIPR = getattr(ecodes, "BTN_GRIPR", 549)
GRIP_CODES = {
    GRIPL,
    GRIPR,
    getattr(ecodes, "BTN_GEAR_DOWN", 336),  # sometimes left grip on older maps
}
# Xbox / DualSense-style right stick click (R3)
THUMBR = getattr(ecodes, "BTN_THUMBR", 318)
THUMBL = getattr(ecodes, "BTN_THUMBL", 317)  # unused for dictate; reserved
# Steam Input keyboard target — Insert is in Steam's picker; F20 usually is not
INSERT = getattr(ecodes, "KEY_INSERT", 110)
F20 = getattr(ecodes, "KEY_F20", 190)  # legacy
STEAM_KEYS = {INSERT, F20}
HOLD_CODES = GRIP_CODES | {THUMBR, THUMBL} | STEAM_KEYS
# Right grip is cancel-only, not hold-to-talk
HOLD_START_CODES = (GRIP_CODES - {GRIPR}) | {THUMBR} | STEAM_KEYS

XBOX_NAME_HINTS = (
    "xbox",
    "x-box",
    "xpad",
    "microsoft",
    "8bitdo",
    "gamepad",
    "controller",
)

_last_fire = 0.0
_lock = threading.Lock()
_hold_active = False


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


def pipeline_busy() -> bool:
    return load_status().get("state") in BUSY_STATES


def is_recording() -> bool:
    return load_status().get("state") in RECORDING_STATES or _hold_active


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


def clear_stop() -> None:
    try:
        STOP_FILE.unlink(missing_ok=True)
    except OSError:
        pass


def signal_stop(reason: str) -> None:
    global _hold_active
    try:
        STOP_FILE.parent.mkdir(parents=True, exist_ok=True)
        STOP_FILE.touch()
    except OSError as exc:
        log(f"stop touch failed: {exc}")
        return
    _hold_active = False
    log(f"stop record: {reason}")


def fire_dictate(reason: str, *, hold: bool = True) -> None:
    global _hold_active
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
    if hold:
        clear_stop()
        env["DICTATE_HOLD"] = "1"
        _hold_active = True
    else:
        env.setdefault("DICTATE_HOLD", "0")
        _hold_active = False
    log(f"dictate{' hold' if hold else ''}: {reason}")
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
        # Cancel always wins; confirm/dictate wait out Whisper/inject.
        # Recording: another press is ignored (release stops instead).
        if action != "cancel":
            if is_recording() and action in {"auto", "dictate"}:
                log(f"already recording ({reason}) — hold until release")
                return
            if pipeline_busy():
                log(f"busy skip ({reason}) — wait for stop/done beep")
                return
        _last_fire = now

    if action == "cancel":
        fire_cancel(reason)
        return
    if action == "confirm":
        fire_confirm(reason)
        return
    if action == "dictate":
        fire_dictate(reason, hold=True)
        return

    # auto: second bind press confirms an open draft instead of re-recording
    if pending_draft():
        fire_confirm(reason)
    else:
        fire_dictate(reason, hold=True)


def ensure_fifo() -> None:
    FIFO.parent.mkdir(parents=True, exist_ok=True)
    if FIFO.exists() and not FIFO.is_fifo():
        FIFO.unlink()
    if not FIFO.exists():
        os.mkfifo(FIFO, 0o600)
    log(f"FIFO ready: {FIFO}")


def looks_like_xbox(name: str, caps: set) -> bool:
    if THUMBR not in caps:
        return False
    if any(h in name for h in XBOX_NAME_HINTS):
        return True
    # Generic pads that expose stick-click + face buttons
    face = {getattr(ecodes, "BTN_SOUTH", 304), getattr(ecodes, "BTN_EAST", 305)}
    return bool(face & caps)


def open_devices():
    devices = []
    for path in Path("/dev/input").glob("event*"):
        try:
            dev = evdev.InputDevice(path)
        except (OSError, PermissionError):
            continue
        name = (dev.name or "").lower()
        caps = set(dev.capabilities().get(ecodes.EV_KEY, []))
        want = False
        if "steam controller" in name or "wireless steam controller" in name:
            if GRIP_CODES & caps:
                want = True
        if looks_like_xbox(name, caps):
            want = True
        if STEAM_KEYS & caps or "keyboard" in name or "steam" in name:
            if STEAM_KEYS & caps or "steam" in name:
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
                if data in {"stop", "release", "end"}:
                    signal_stop("fifo:stop")
                elif data in {"", "fire", "dictate", "1", "auto", "start", "hold"}:
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
                    if event.type != ecodes.EV_KEY:
                        continue
                    # 1 = down, 0 = up, 2 = repeat (ignore)
                    if event.value == 2:
                        continue
                    if event.value == 0:
                        # Release → stop hold-to-talk capture
                        if event.code in HOLD_START_CODES and is_recording():
                            signal_stop(f"release:{event.code}:{dev.name}")
                        continue
                    if event.value != 1:
                        continue
                    if event.code == GRIPR:
                        # Steam Controller right grip discards an open draft (Esc)
                        if is_recording():
                            signal_stop(f"gripR-abort:{dev.name}")
                            fire_cancel(f"gripR-cancel-while-rec:{dev.name}")
                        elif pending_draft():
                            fire(f"gripR-cancel:{dev.name}", "cancel")
                        else:
                            log("right grip ignored (no draft)")
                    elif event.code in GRIP_CODES:
                        fire(f"grip:{dev.name}:{event.code}", "auto")
                    elif event.code == THUMBR:
                        fire(f"R3:{dev.name}", "auto")
                    elif event.code in STEAM_KEYS:
                        fire(f"key{event.code}:{dev.name}", "auto")
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
    clear_stop()
    t = threading.Thread(target=fifo_loop, name="fifo", daemon=True)
    t.start()
    devices = open_devices()
    log(
        "ready (hold SC left grip / Xbox R3 / Insert to talk; release to send; "
        f"draft TTL={DRAFT_TTL_S:.0f}s if DICTATE_SEND_MODE=draft)"
    )
    evdev_loop(devices)
    return 0


if __name__ == "__main__":
    sys.exit(main())
