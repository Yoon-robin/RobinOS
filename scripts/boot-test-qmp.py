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
QCODES = {" ": "spc", "\n": "ret", "-": "minus", ".": "dot", "/": "slash", ";": "semicolon",
          "'": "apostrophe", "\\": "backslash", ",": "comma", "=": "equal"}
# Characters typed with Shift on a US keyboard
SHIFTED = {"(": "9", ")": "0", "&": "7", "~": "grave_accent", ">": "dot", "<": "comma", "?": "slash", "$": "4", "%": "5",
           '"': "apostrophe", "{": "bracket_left", "}": "bracket_right", ":": "semicolon", "_": "minus"}


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
    # the key, so give it time to catch up between keys. Faster typing (20 ms a key)
    # left Shift stuck halfway through long text, so keep this pace.
    time.sleep(0.15 * SPEED)


def hold(qmp, key, down):
    """Press (down=True) or let go of a key, for shots taken while it is held."""
    qmp.execute("input-send-event", events=[{"type": "key", "data": {"down": down, "key": {"type": "qcode", "data": key}}}])
    time.sleep(0.15 * SPEED)


SCREEN = (1600, 900)  # the VGA mode in boot-test.sh and wsl-build.ps1


def move(qmp, x, y):
    """Move the pointer to screen pixel (x, y) through the usb-tablet (absolute 0..32767)."""
    qmp.execute("input-send-event", events=[
        {"type": "abs", "data": {"axis": "x", "value": round(x * 32767 / (SCREEN[0] - 1))}},
        {"type": "abs", "data": {"axis": "y", "value": round(y * 32767 / (SCREEN[1] - 1))}},
    ])
    time.sleep(0.2 * SPEED)


def click(qmp, x, y, button="left"):
    """Click at screen pixel (x, y)."""
    move(qmp, x, y)
    for down in (True, False):
        qmp.execute("input-send-event", events=[{"type": "btn", "data": {"down": down, "button": button}}])
        time.sleep(0.1 * SPEED)


def type_text(qmp, text):
    # A character missing from the tables used to vanish silently ("printf '%s'" went
    # in as "printf 's'", 2026-10-10), so fail before typing anything instead
    missing = sorted(set(ch for ch in text if not (ch.isascii() and ch.isalnum()) and ch not in QCODES and ch not in SHIFTED))
    if missing:
        raise ValueError(f"type_text can't type {missing}: add them to QCODES or SHIFTED")
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
    # (Linux basics missions) in the learning center, which we close again
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
    # Alt+F4 with no window left asks for the power menu, like Windows' shutdown dialog
    keys(qmp, "alt", "f4")
    wait(2)
    shot(qmp, "power-menu")
    keys(qmp, "esc")
    wait(1)
    # Win+X like Windows' quick link menu: the system tools above the launcher button
    keys(qmp, "meta_l", "x")
    wait(2)
    shot(qmp, "quick-links")
    keys(qmp, "esc")
    wait(1)

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
    # A mouse click on the 방해 금지 tile (left column, second row): on, then off
    click(qmp, 1337, 197)
    wait(1)
    shot(qmp, "quick-settings-dnd")
    click(qmp, 1337, 197)
    wait(1)
    # The Wi-Fi tile's arrow (top left tile, right edge) opens the connect panel; the
    # VM has no Wi-Fi card, so it says so and points at the wired connection
    click(qmp, 1399, 131)
    wait(2)
    shot(qmp, "connect-wifi")
    keys(qmp, "esc")
    wait(2)
    # Super+Alt+D opens the clock's month calendar (a click on the clock does too)
    keys(qmp, "meta_l", "alt", "d")
    wait(2)
    shot(qmp, "calendar")
    keys(qmp, "esc")
    wait(1)
    # Super+F1: every shortcut on one card, with the terminal's copy and paste keys
    keys(qmp, "meta_l", "f1")
    wait(2)
    shot(qmp, "shortcuts")
    keys(qmp, "esc")
    wait(1)

    keys(qmp, "meta_l", "ret")
    wait(6)
    type_text(qmp, "ipconfig\n")
    wait(2)
    shot(qmp, "terminal-windows-hint")
    type_text(qmp, "clear\n")
    type_text(qmp, "robinctl learn show 1\n")
    wait(2)
    shot(qmp, "terminal-learn")
    # robinctl audit, like Windows Security's overview: open ports, sshd, permissions,
    # snapshots (none in the live session), firewall, disk encryption
    type_text(qmp, "clear; robinctl audit\n")
    wait(3)
    shot(qmp, "security-audit")
    # Solve mission 1, so the launcher's learning entry shows "1/40" in light-launcher
    type_text(qmp, "mkdir -p ~/practice/notes && robinctl learn check 1 >/dev/null\n")
    wait(1)
    # Title bar buttons (desktop/dconf) as GTK, Firefox and Qt apps read them
    type_text(qmp, "clear; gdbus call --session --dest org.freedesktop.portal.Desktop"
              " --object-path /org/freedesktop/portal/desktop --method org.freedesktop.portal.Settings.ReadOne"
              " org.gnome.desktop.wm.preferences button-layout\n")
    wait(3)
    shot(qmp, "button-layout")

    # Minimize like the Windows taskbar: the dock's click on an app goes through the
    # same shell function as this IPC call. The focused terminal minimizes itself, and
    # a background job brings it back a few seconds later.
    ipc = "qs ipc -p /usr/share/robinos/shell call shell "
    type_text(qmp, "clear; (sleep 6; " + ipc + "toggleApp foot) & " + ipc + "toggleApp foot\n")
    wait(3)
    shot(qmp, "minimized")
    wait(7)
    shot(qmp, "restored")
    # Windows' snap: Win+Left puts the terminal on the left half, Win+Up maximizes it,
    # Win+Down twice brings back the half and then the size it had before
    keys(qmp, "meta_l", "left")
    wait(2)
    shot(qmp, "snap-left")
    keys(qmp, "meta_l", "up")
    wait(2)
    shot(qmp, "snap-maximized")
    keys(qmp, "meta_l", "down")
    wait(1)
    keys(qmp, "meta_l", "down")
    wait(2)
    shot(qmp, "snap-restored")
    # Win+Ctrl+Right/Left like Windows' virtual desktops: an empty workspace 2, and back
    keys(qmp, "meta_l", "ctrl", "right")
    wait(2)
    shot(qmp, "workspace-next")
    keys(qmp, "meta_l", "ctrl", "left")
    wait(2)
    # Super+D hides every window on the workspace; pressed again, they come back
    keys(qmp, "meta_l", "d")
    wait(2)
    shot(qmp, "show-desktop")
    keys(qmp, "meta_l", "d")
    wait(2)
    shot(qmp, "desktop-back")
    # Win+Shift+S like Windows' snipping tool: slurp waits for a region, Esc cancels
    keys(qmp, "meta_l", "shift", "s")
    wait(2)
    shot(qmp, "snipping")
    keys(qmp, "esc")
    wait(1)
    # Shift+Print saves the whole screen; the toast opens the picture on a click and
    # has a "폴더 열기" button, like Windows' snipping tool toast
    keys(qmp, "shift", "print")
    wait(2)
    shot(qmp, "screenshot-toast")
    # Win+V like Windows' clipboard history: copy something, then open the list
    type_text(qmp, "clear; wl-copy clipboard-test-robinos\n")
    wait(2)
    keys(qmp, "meta_l", "v")
    wait(3)
    shot(qmp, "clipboard")
    keys(qmp, "esc")
    wait(1)
    # Win+. like Windows' emoji panel: "heart" finds the hearts, Enter types the
    # first one into the terminal (wtype); Ctrl+U clears the line again
    type_text(qmp, "clear\n")
    keys(qmp, "meta_l", "dot")
    wait(2)
    type_text(qmp, "heart")
    wait(1)
    shot(qmp, "emoji")
    keys(qmp, "ret")
    wait(2)
    shot(qmp, "emoji-typed")
    keys(qmp, "ctrl", "u")
    # A notification toast bottom right ("알림" / "오른쪽 아래에 떠요": QMP only types
    # ASCII, so bash's \u escapes spell the Korean)
    type_text(qmp, "clear; notify-send -a RobinOS $'\\uc54c\\ub9bc'"
              " $'\\uc624\\ub978\\ucabd \\uc544\\ub798\\uc5d0 \\ub5a0\\uc694'\n")
    wait(2)
    shot(qmp, "notification")
    # Super+N opens the notification center with that notification in it
    keys(qmp, "meta_l", "n")
    wait(2)
    shot(qmp, "notification-center")
    # Like Windows, a click on an old notification opens it: the Shift+Print toast
    # (second in the list) is long gone, so its x-robinos-open hint opens the picture
    # in the image viewer. Ctrl+W closes Loupe (in the terminal it only erases a word)
    click(qmp, 1410, 220)
    wait(4)
    shot(qmp, "notification-opened")
    keys(qmp, "ctrl", "w")
    wait(2)
    # The Bluetooth tile's arrow, through IPC since the VM has no adapter (the tile
    # is greyed out); a click outside the card closes it
    type_text(qmp, "clear; " + ipc + "connect bluetooth\n")
    wait(2)
    shot(qmp, "connect-bluetooth")
    click(qmp, 400, 400)
    wait(1)
    # The sound panel (also the arrow after the volume slider), found in the launcher
    # by Windows' "volume mixer": the VM's sound card as output and microphone, and
    # pw-play (30 s of silence) under the app volumes
    type_text(qmp, "clear; python -c \"import wave;w=wave.open('/tmp/s.wav','wb');w.setnchannels(2);"
              "w.setsampwidth(2);w.setframerate(48000);w.writeframes(bytes(5760000))\"; pw-play /tmp/s.wav &\n")
    wait(2)
    keys(qmp, "meta_l", "spc")
    wait(2)
    type_text(qmp, "mixer")
    wait(2)
    keys(qmp, "ret")
    wait(3)
    shot(qmp, "sound")
    # Tab reaches the device rows, like the other buttons (a focus ring)
    keys(qmp, "tab")
    wait(1)
    shot(qmp, "sound-keyboard")
    keys(qmp, "esc")
    wait(1)
    # Apps' tray icons in the bar, like the Windows notification area: a test item
    # (scripts/sni-test-item.sh, in the ISO) shows up left of 한/A, and a click on it
    # reaches the app
    type_text(qmp, "clear; bash /opt/robinos/scripts/sni-test-item.sh &\n")
    wait(4)
    click(qmp, 1454, 18)
    wait(1)
    type_text(qmp, "cat /tmp/sni-activated\n")
    wait(1)
    shot(qmp, "tray")
    # The wheel over the bar's status icons turns the volume down (4 steps of 5%),
    # and the volume indicator shows above the dock
    for _ in range(4):
        click(qmp, 1528, 18, "wheel-down")
    wait(0.5)
    shot(qmp, "volume-wheel")
    # Resting on the terminal in the dock shows its window above it, like the
    # Windows taskbar (x 775 on the 1600 px screen)
    move(qmp, 775, 860)
    wait(2)
    shot(qmp, "dock-preview")
    move(qmp, 800, 400)
    wait(1)
    # "배경으로 설정" in Files and Image Viewer goes through the Wallpaper portal to
    # robinos-wallpaper-portal; the same call here sets the RobinOS logo as the
    # wallpaper. Then the launcher's "기본 배경화면으로" brings the drawn one back.
    type_text(qmp, "clear; gdbus call --session --dest org.freedesktop.portal.Desktop"
              " --object-path /org/freedesktop/portal/desktop --method org.freedesktop.portal.Wallpaper.SetWallpaperURI"
              ' "" file:///opt/robinos/assets/brand/robinos-logo.svg {}\n')
    wait(4)
    keys(qmp, "meta_l", "d")
    wait(2)
    shot(qmp, "wallpaper")
    keys(qmp, "meta_l", "spc")
    wait(2)
    type_text(qmp, "wallpaper")
    wait(2)
    keys(qmp, "down")
    keys(qmp, "ret")
    wait(3)
    shot(qmp, "wallpaper-reset")
    keys(qmp, "meta_l", "d")
    wait(2)

    # Pinning to the dock like the Windows taskbar, with real right clicks. The
    # running calculator shows up after the browser (x 900 on the 1600 px screen);
    # a right click pins it, a second one unpins it.
    type_text(qmp, "clear; gnome-calculator > /dev/null 2>&1 &\n")
    wait(5)
    click(qmp, 900, 860, "right")
    wait(2)
    shot(qmp, "dock-pinned")
    click(qmp, 900, 860, "right")
    wait(1)
    # Alt+Tab like Windows: with Alt held, the two windows with their pictures, the
    # terminal (used before) chosen; letting go switches to it. A quick Alt+Tab
    # comes back to the calculator.
    hold(qmp, "alt", True)
    keys(qmp, "tab")
    wait(2)
    shot(qmp, "alt-tab")
    hold(qmp, "alt", False)
    wait(1)
    shot(qmp, "alt-tab-switched")
    keys(qmp, "alt", "tab")
    wait(1)
    # Win+Tab like Windows' task view: both windows under "작업 공간 1 · 지금 화면"
    keys(qmp, "meta_l", "tab")
    wait(2)
    shot(qmp, "task-view")
    keys(qmp, "esc")
    wait(1)
    keys(qmp, "alt", "f4")  # the calculator has the focus
    wait(2)
    # The launcher's right click pins an app too, like "작업 표시줄에 고정":
    # "calc" puts the calculator first, under "윈도우에서 쓰던 이름"
    keys(qmp, "meta_l", "spc")
    wait(3)
    type_text(qmp, "calc")
    wait(2)
    click(qmp, 800, 267, "right")
    wait(2)
    shot(qmp, "launcher-pin")
    # Opening it from the launcher puts it under "최근에 연 앱" (light-launcher)
    keys(qmp, "ret")
    wait(4)
    keys(qmp, "alt", "f4")
    wait(2)
    type_text(qmp, "clear; " + "qs ipc -p /usr/share/robinos/shell call shell " + "unpinFromDock org.gnome.Calculator\n")
    wait(2)
    # Shift+Delete on an app, like the Start menu's "제거": the calculator is one of
    # RobinOS's own apps, so robinctl keeps it and says why (Enter closes the window)
    keys(qmp, "meta_l", "spc")
    wait(3)
    type_text(qmp, "calc")
    wait(2)
    keys(qmp, "shift", "delete")
    wait(4)
    shot(qmp, "app-remove-kept")
    keys(qmp, "ret")
    wait(2)

    # robinos-shell starts the shell again when it dies
    type_text(qmp, "clear; pkill -x qs; sleep 4; grep -a robinos-shell .local/state/robinos/shell.log\n")
    wait(7)
    shot(qmp, "shell-restarted")

    # A file GTK apps noted as opened (recently-used.xbel): the empty launcher lists it
    # under "최근 파일" in light-launcher, like the Start menu's recommended files
    type_text(qmp, "clear; mkdir -p ~/.local/share; echo '<?xml version=\"1.0\"?><xbel version=\"1.0\">"
              "<bookmark href=\"file://'\"$HOME\"'/practice/hello.txt\" modified=\"2026-10-10T00:00:00Z\"/></xbel>'"
              " > ~/.local/share/recently-used.xbel; cat ~/.local/share/recently-used.xbel\n")
    wait(3)
    shot(qmp, "recent-file-written")
    # Light mode, through the shell's IPC (the same as the quick settings tile)
    type_text(qmp, "clear; qs ipc -p /usr/share/robinos/shell call shell setDark false\n")
    wait(4)
    type_text(qmp, "robinctl learn\n")
    wait(2)
    shot(qmp, "light-terminal")
    keys(qmp, "meta_l", "spc")
    wait(3)
    shot(qmp, "light-launcher")
    # Files by name, like the Start menu: mission 1 made ~/practice/notes
    type_text(qmp, "notes")
    wait(3)
    shot(qmp, "launcher-files")
    keys(qmp, "esc")
    wait(2)
    # The learning center opened again after Alt+F4 closed it: mission 1 is ticked off
    type_text(qmp, "clear; " + ipc + "learnCenter\n")
    wait(3)
    shot(qmp, "light-learn-center")
    # Clicking a mission opens it in a terminal (mission 2's row)
    click(qmp, 800, 437)
    wait(4)
    shot(qmp, "learn-center-mission")
    keys(qmp, "alt", "f4")  # the new terminal has the focus
    wait(2)
    # At the end of the list, the ten CTF challenges as one more group
    for _ in range(40):
        click(qmp, 800, 500, "wheel-down")
    wait(1)
    shot(qmp, "learn-center-ctf")
    # The learning center's own close button (its title bar, top right)
    click(qmp, 1156, 102)
    wait(2)
    keys(qmp, "meta_l", "s")
    wait(3)
    shot(qmp, "light-quick-settings")
    keys(qmp, "meta_l", "s")
    wait(2)
    # 화면 배율 125%, through the same shell function as the quick settings
    # buttons: the whole desktop grows, and the choice is saved for the next login
    type_text(qmp, "clear; " + ipc + "setScale 1.25; sleep 2; cat .local/state/robinos/display-scale\n")
    wait(5)
    shot(qmp, "scale-125")
    type_text(qmp, "clear; " + ipc + "setScale 1\n")
    wait(3)
    # 야간 모드 starts hyprsunset (4500 K) and the second call stops it. The colors
    # need the driver's KMS CTM, which the test VM's bochs-drm lacks, so the shot
    # shows the running process (and the tile's VM note) instead of a warm screen
    type_text(qmp, "clear; " + ipc + "toggleNightLight; sleep 1; pgrep -a hyprsunset\n")
    wait(3)
    shot(qmp, "night-light")
    type_text(qmp, "clear; " + ipc + "toggleNightLight\n")
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
