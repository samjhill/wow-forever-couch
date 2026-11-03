#!/usr/bin/env python3
"""Watch FIFO + Steam Controller left grip + KEY_F20; run dictate-push-to-talk.sh."""
from __future__ import annotations

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

BASE = Path(os.environ.get("WOW_FOREVER_COUCH") or os.environ.get("WOW_BAZZITE_SETUP") or Path(__file__).resolve().parents[1])
DICTATE = BASE / "scripts" / "dictate-push-to-talk.sh"
FIFO = BASE / "config" / "dictate.trigger"
COOLDOWN_S = float(os.environ.get("DICTATE_COOLDOWN", "1.5"))

# Linux BTN_GRIPL / BTN_GRIPR (newer) and fallbacks
GRIP_CODES = {
    getattr(ecodes, "BTN_GRIPL", 548),
    getattr(ecodes, "BTN_GRIPR", 549),
    getattr(ecodes, "BTN_GEAR_DOWN", 336),  # sometimes left grip on older maps
}
F20 = getattr(ecodes, "KEY_F20", 190)

_last_fire = 0.0
_lock = threading.Lock()


def log(msg: str) -> None:
    print(f"[dictate-daemon] {msg}", flush=True)


def fire(reason: str) -> None:
    global _last_fire
    with _lock:
        now = time.time()
        if now - _last_fire < COOLDOWN_S:
            log(f"cooldown skip ({reason})")
            return
        _last_fire = now
    log(f"trigger: {reason}")
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
    subprocess.Popen(
        [str(DICTATE)],
        env=env,
        cwd=str(BASE),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


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
            # Also watch keyboards / SC keyboard iface for F20
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
                data = line.decode("utf-8", "replace").strip()
                if data == "" or data.lower() in {"fire", "dictate", "1"}:
                    fire("fifo")
                else:
                    fire(f"fifo:{data[:40]}")
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
    grip_down = set()
    while True:
        try:
            r, _, _ = select.select(list(mapping), [], [], 5.0)
        except (OSError, ValueError):
            # Device disappeared — rescan
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
                    if event.code in GRIP_CODES and event.value == 1:
                        # Left grip only if we can tell; BTN_GRIPL preferred
                        if event.code == getattr(ecodes, "BTN_GRIPR", 549):
                            continue  # ignore right grip
                        fire(f"grip:{dev.name}:{event.code}")
                    elif event.code == F20 and event.value == 1:
                        fire(f"F20:{dev.name}")
            except (OSError, BlockingIOError):
                continue


def main() -> int:
    if not DICTATE.is_file():
        log(f"missing dictate script: {DICTATE}")
        return 2
    ensure_fifo()
    t = threading.Thread(target=fifo_loop, name="fifo", daemon=True)
    t.start()
    devices = open_devices()
    log("ready")
    evdev_loop(devices)
    return 0


if __name__ == "__main__":
    sys.exit(main())
