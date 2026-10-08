#!/usr/bin/env python3
"""Drive a booting RobinOS VM over QMP and take screenshots.

Usage: boot-test-qmp.py <qmp-socket | tcp:host:port> <output-dir> [speed]

speed multiplies every wait (1 with KVM, about 4 with TCG). The scenario:
boot -> welcome wizard (every step, then its missions terminal) -> desktop ->
launcher (search, Windows app name) -> installer (first two steps) -> quick settings
(also with Tab) -> terminal with a Windows command and the first learning mission
-> minimize and restore the terminal -> Super+D twice -> kill the shell and see
it come back -> light mode (terminal,
launcher, quick settings) -> lock screen -> unlock with the live password.
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
QCODES = {" ": "spc", "\n": "ret", "-": "minus", ".": "dot", "/": "slash", ";": "semicolon"}
# Characters typed with Shift on a US keyboard
SHIFTED = {"(": "9", ")": "0", "&": "7"}


class Qmp:
    def __init__(self, path):
        """path: a unix socket, or tcp:HOST:PORT (QEMU on Windows, see wsl-build.ps1)."""
        self.sock = None
        for _ in range(120):
            try:
                if path.startswith("tcp:"):
                    host, port = path[4:].rsplit(":", 1)
                    sock = socket.create_connection((host, int(port)))
                else:
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
    # A slow (TCG) guest that falls behind sees the release late and auto-repeats
    # the key, so give it time to catch up between keys.
    time.sleep(0.15 * SPEED)


def type_text(qmp, text):
    for ch in text:
        if ch.isupper():
            keys(qmp, "shift", ch.lower())
        elif ch in SHIFTED:
            keys(qmp, "shift", SHIFTED[ch])
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

    # Boot: live autologin goes straight into the RobinOS session, which opens
    # the welcome wizard on first login
    for seconds, name in ((30, "boot"), (30, "boot"), (30, "session"), (30, "welcome")):
        wait(seconds)
        shot(qmp, name)

    # Wizard: Enter moves to the next step; the last one opens the default goal
    # (Linux basics missions) in a terminal, which we close again
    for name in ("welcome-theme", "welcome-hangul", "welcome-goal", "welcome-tour"):
        keys(qmp, "ret")
        wait(2)
        shot(qmp, name)
    keys(qmp, "ret")
    wait(6)
    shot(qmp, "welcome-done")
    keys(qmp, "alt", "f4")
    wait(2)
    shot(qmp, "desktop")

    keys(qmp, "meta_l", "spc")
    wait(3)
    shot(qmp, "launcher")
    type_text(qmp, "term")
    wait(2)
    shot(qmp, "launcher-search")
    keys(qmp, "ctrl", "a")  # select the query so typing replaces it
    type_text(qmp, "notepad")
    wait(2)
    shot(qmp, "launcher-windows-name")
    keys(qmp, "esc")
    wait(2)

    # Installer: first in the launcher's list in the live session. The VM has a
    # blank disk, so the disk step shows one disk card. Nothing gets installed.
    keys(qmp, "meta_l", "spc")
    wait(3)
    keys(qmp, "ret")
    wait(4)
    shot(qmp, "installer")
    keys(qmp, "ret")
    wait(4)
    shot(qmp, "installer-disk")
    keys(qmp, "alt", "f4")
    wait(2)

    keys(qmp, "meta_l", "s")
    wait(3)
    shot(qmp, "quick-settings")
    # Keyboard only: Tab moves a focus ring over the buttons and tiles
    for _ in range(3):
        keys(qmp, "tab")
        wait(0.5)
    shot(qmp, "quick-settings-keyboard")
    keys(qmp, "meta_l", "s")
    wait(2)

    keys(qmp, "meta_l", "ret")
    wait(6)
    type_text(qmp, "ipconfig\n")
    wait(2)
    shot(qmp, "terminal-windows-hint")
    type_text(qmp, "clear\n")
    type_text(qmp, "robinctl learn show 1\n")
    wait(2)
    shot(qmp, "terminal-learn")

    # Minimize like the Windows taskbar: the dock's click on an app goes through the
    # same shell function as this IPC call. The focused terminal minimizes itself, and
    # a background job brings it back a few seconds later.
    ipc = "qs ipc -p /usr/share/robinos/shell call shell "
    type_text(qmp, "clear; (sleep 6; " + ipc + "toggleApp foot) & " + ipc + "toggleApp foot\n")
    wait(3)
    shot(qmp, "minimized")
    wait(7)
    shot(qmp, "restored")
    # Super+D hides every window on the workspace; pressed again, they come back
    keys(qmp, "meta_l", "d")
    wait(2)
    shot(qmp, "show-desktop")
    keys(qmp, "meta_l", "d")
    wait(2)
    shot(qmp, "desktop-back")

    # robinos-shell starts the shell again when it dies
    type_text(qmp, "clear; pkill -x qs; sleep 4; grep -a robinos-shell .local/state/robinos/shell.log\n")
    wait(7)
    shot(qmp, "shell-restarted")

    # Light mode, through the shell's IPC (the same as the quick settings tile)
    type_text(qmp, "clear; qs ipc -p /usr/share/robinos/shell call shell setDark false\n")
    wait(4)
    type_text(qmp, "robinctl learn\n")
    wait(2)
    shot(qmp, "light-terminal")
    keys(qmp, "meta_l", "spc")
    wait(3)
    shot(qmp, "light-launcher")
    keys(qmp, "esc")
    wait(2)
    keys(qmp, "meta_l", "s")
    wait(3)
    shot(qmp, "light-quick-settings")
    keys(qmp, "meta_l", "s")
    wait(2)
    type_text(qmp, "qs ipc -p /usr/share/robinos/shell call shell setDark true\n")
    wait(3)

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
