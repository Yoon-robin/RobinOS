#!/usr/bin/env python3
"""Drive a booting RobinOS VM over QMP and take screenshots.

Usage: boot-test-qmp.py <qmp-socket> <output-dir> [speed]

speed multiplies every wait (1 with KVM, about 4 with TCG). The scenario:
boot -> desktop -> launcher -> quick settings -> terminal with a Windows
command -> lock screen -> unlock with the live password.
"""

import json
import os
import socket
import sys
import time

SOCK = sys.argv[1]
OUT = sys.argv[2]
SPEED = float(sys.argv[3]) if len(sys.argv) > 3 else 1.0
LIVE_PASSWORD = "robin"

# Characters we can type, mapped to QEMU key codes (qcode)
QCODES = {" ": "spc", "\n": "ret", "-": "minus", ".": "dot", "/": "slash"}


class Qmp:
    def __init__(self, path):
        self.sock = None
        for _ in range(120):
            try:
                sock = socket.socket(socket.AF_UNIX)
                sock.connect(path)
                self.sock = sock
                break
            except OSError:
                time.sleep(1)
        if self.sock is None:
            raise RuntimeError("could not connect to QMP (did QEMU start?)")
        self.file = self.sock.makefile("rwb")
        self._read()  # greeting
        self.execute("qmp_capabilities")

    def _read(self):
        line = self.file.readline()
        if not line:
            raise RuntimeError("QMP connection closed")
        return json.loads(line)

    def execute(self, command, **arguments):
        message = {"execute": command}
        if arguments:
            message["arguments"] = arguments
        self.file.write((json.dumps(message) + "\n").encode())
        self.file.flush()
        while True:
            reply = self._read()
            if "event" in reply:
                continue
            return reply


def wait(seconds):
    time.sleep(seconds * SPEED)


def keys(qmp, *names):
    """Press a key combination, e.g. keys(qmp, "meta_l", "spc")."""
    qmp.execute("send-key", keys=[{"type": "qcode", "data": n} for n in names], **{"hold-time": 80})
    time.sleep(0.15)


def type_text(qmp, text):
    for ch in text:
        if ch.isupper():
            keys(qmp, "shift", ch.lower())
        else:
            keys(qmp, QCODES.get(ch, ch))


shot_number = 0


def shot(qmp, name):
    global shot_number
    shot_number += 1
    base = os.path.join(OUT, f"{shot_number:02d}-{name}")
    reply = qmp.execute("screendump", filename=base + ".png", format="png")
    if "error" in reply:  # QEMU before 7.1 only writes PPM
        reply = qmp.execute("screendump", filename=base + ".ppm")
    print(f"{shot_number:02d}-{name}: {'ok' if 'return' in reply else reply}", flush=True)


def main():
    qmp = Qmp(SOCK)

    # Boot: live autologin goes straight into the RobinOS session
    for seconds, name in ((30, "boot"), (30, "boot"), (30, "desktop"), (30, "desktop")):
        wait(seconds)
        shot(qmp, name)

    keys(qmp, "meta_l", "spc")
    wait(3)
    shot(qmp, "launcher")
    type_text(qmp, "term")
    wait(2)
    shot(qmp, "launcher-search")
    keys(qmp, "esc")
    wait(2)

    keys(qmp, "meta_l", "s")
    wait(3)
    shot(qmp, "quick-settings")
    keys(qmp, "meta_l", "s")
    wait(2)

    keys(qmp, "meta_l", "ret")
    wait(6)
    type_text(qmp, "ipconfig\n")
    wait(2)
    shot(qmp, "terminal-windows-hint")

    keys(qmp, "meta_l", "l")
    wait(5)
    shot(qmp, "lock-screen")
    type_text(qmp, LIVE_PASSWORD + "\n")
    wait(5)
    shot(qmp, "unlocked")

    try:
        qmp.execute("quit")
    except RuntimeError:
        pass  # QEMU closes the socket while quitting


if __name__ == "__main__":
    try:
        main()
    except Exception as error:  # keep the screenshots taken so far
        print(f"QMP scenario stopped: {error}", flush=True)
