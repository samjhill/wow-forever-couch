#!/usr/bin/env python3
"""Turn Bluetooth Xbox right-stick click into the dictation FIFO.

The kernel hid-microsoft driver binds the Xbox Wireless Controller (045e:02e0)
with a 10-button report. Right-stick click is the next bit (SDL b10) and the
descriptor marks that bit constant, so /dev/input never emits BTN_THUMBR.
Steam's virtual 360 pad therefore never sees the click, and the dictate
daemon's R3 watch stays quiet.

This reads the world-readable hidraw node, watches that bit, and writes
"start" / "stop" to the dictate FIFO the daemon already reads.
"""
from __future__ import annotations

import os
import select
import sys
import time
from pathlib import Path

# Report id 1, after four 16-bit axes and the trigger/hat fields:
# 10 one-bit buttons, then 6 bits the descriptor calls constant.
# Bit 10 of that 16-bit word is the first undeclared button (right stick).
R3_BIT = int(os.environ.get("XBOX_R3_BIT", "10"))
HID_MATCH = os.environ.get("XBOX_HID_MATCH", "045E:02E0").upper()


def log(msg: str) -> None:
    print(f"xbox-r3: {msg}", flush=True)


def fifo_path() -> Path:
    explicit = os.environ.get("DICTATE_FIFO")
    if explicit:
        return Path(explicit)
    candidates = [
        Path("/home/sam/Projects/wow-bazzite-setup/config/dictate.trigger"),
        Path(os.environ.get("WOW_FOREVER_COUCH", "")) / "config" / "dictate.trigger",
        Path(os.environ.get("WOW_BAZZITE_SETUP", "")) / "config" / "dictate.trigger",
    ]
    for path in candidates:
        if path.is_fifo():
            return path
    return candidates[0]


def find_hidraw() -> Path | None:
    root = Path("/sys/class/hidraw")
    if not root.is_dir():
        return None
    for node in sorted(root.glob("hidraw*")):
        uevent = node / "device" / "uevent"
        try:
            text = uevent.read_text(errors="replace").upper()
        except OSError:
            continue
        if HID_MATCH in text or "XBOX WIRELESS CONTROLLER" in text:
            dev = Path("/dev") / node.name
            if dev.exists():
                return dev
    return None


def button_word(data: bytes) -> int | None:
    if len(data) < 16 or data[0] != 0x01:
        return None
    return data[14] | (data[15] << 8)


def write_fifo(path: Path, word: str) -> None:
    fd = os.open(path, os.O_WRONLY | os.O_NONBLOCK)
    try:
        os.write(fd, f"{word}\n".encode())
    finally:
        os.close(fd)


def watch(dev: Path, fifo: Path) -> None:
    log(f"watching {dev} bit {R3_BIT} → {fifo}")
    fd = os.open(dev, os.O_RDONLY | os.O_NONBLOCK)
    held = False
    try:
        while True:
            readable, _, _ = select.select([fd], [], [], 1.0)
            if not readable:
                if not dev.exists():
                    return
                continue
            try:
                data = os.read(fd, 64)
            except BlockingIOError:
                continue
            if not data:
                return
            word = button_word(data)
            if word is None:
                continue
            down = bool(word & (1 << R3_BIT))
            if down == held:
                continue
            held = down
            cmd = "start" if down else "stop"
            try:
                write_fifo(fifo, cmd)
                log(f"R3 {cmd}")
            except OSError as exc:
                log(f"fifo {cmd} failed: {exc}")
    finally:
        os.close(fd)


def main() -> int:
    fifo = fifo_path()
    log(f"fifo {fifo}")
    while True:
        dev = find_hidraw()
        if dev is None:
            time.sleep(1.0)
            continue
        try:
            watch(dev, fifo)
        except OSError as exc:
            log(f"{dev} closed: {exc}")
        time.sleep(0.5)


if __name__ == "__main__":
    sys.exit(main())
