pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Networking
import Quickshell.Bluetooth

// Shared shell state: which overlay is open, clock, audio, network, input method,
// brightness, lab status and the actions the bar, dock and launcher call.
Singleton {
    id: root

    property bool launcherOpen: false
    property bool quickSettingsOpen: false
    property var overlayScreen: null
    property bool dnd: false
    // Kept on by an IdleInhibitor in each Bar window
    property bool keepAwake: false

    readonly property string userName: Quickshell.env("USER") ?? "user"

    // ---- Window placement: floating like Windows (default) or Hyprland tiling ----

    readonly property bool tiling: desktopSettings.tiling

    function setTiling(value) {
        desktopSettings.tiling = value;
        desktopStore.writeAdapter();
        applyTiling();
    }

    // robinos.lua keeps the float-by-default window rule in a global handle.
    function applyTiling() {
        Quickshell.execDetached(["hyprctl", "eval", "robinos.floatByDefault:set_enabled(" + (!tiling) + ")"]);
    }

    // A Hyprland config reload rebuilds its Lua state, which re-enables the float
    // rule and resets the light-theme border colors. Apply our choices again.
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "configreloaded") {
                root.applyTiling();
                Theme.applySystem();
            }
        }
    }

    FileView {
        id: desktopStore

        path: Quickshell.statePath("desktop.json")
        printErrors: false

        onLoaded: root.applyTiling()

        JsonAdapter {
            id: desktopSettings

            property bool tiling: false
        }
    }
    property string hostName: "robinos"

    function findIn(list, predicate) {
        if (!list)
            return null;
        for (let i = 0; i < list.length; i++) {
            if (predicate(list[i]))
                return list[i];
        }
        return null;
    }

    function toArray(list) {
        const out = [];
        if (!list)
            return out;
        for (let i = 0; i < list.length; i++)
            out.push(list[i]);
        return out;
    }

    // ---- Screens and overlays ----

    readonly property var focusedScreen: {
        const name = Hyprland.focusedMonitor?.name ?? "";
        return findIn(Quickshell.screens, s => s.name === name) ?? Quickshell.screens[0];
    }

    // The launcher also shows the clipboard history (Win+V, Launcher.qml)
    property bool launcherClipboard: false

    function toggleLauncher() {
        if (welcomeOpen)
            return;
        if (launcherOpen) {
            launcherOpen = false;
            return;
        }
        quickSettingsOpen = false;
        overlayScreen = focusedScreen;
        launcherClipboard = false;
        launcherOpen = true;
    }

    function toggleClipboard() {
        if (welcomeOpen)
            return;
        if (launcherOpen) {
            launcherOpen = false;
            return;
        }
        quickSettingsOpen = false;
        overlayScreen = focusedScreen;
        launcherClipboard = true;
        launcherOpen = true;
    }

    function toggleQuickSettings(screen) {
        if (welcomeOpen)
            return;
        if (quickSettingsOpen) {
            quickSettingsOpen = false;
            return;
        }
        launcherOpen = false;
        overlayScreen = screen ?? focusedScreen;
        quickSettingsOpen = true;
    }

    // ---- Installer (Installer.qml), only offered in the live session ----

    property bool installerOpen: false
    // archiso mounts the boot medium under /run/archiso
    property bool isLive: false

    Process {
        command: ["test", "-d", "/run/archiso"]
        running: true
        onExited: (exitCode, exitStatus) => root.isLive = exitCode === 0
    }

    function openInstaller() {
        launcherOpen = false;
        quickSettingsOpen = false;
        installerOpen = true;
    }

    // ---- First-login welcome wizard (Welcome.qml) ----

    property bool welcomeOpen: false
    readonly property string welcomeGoal: welcomeSettings.goal
    readonly property string imeShortcut: welcomeSettings.imeShortcut

    FileView {
        id: welcomeStore

        path: Quickshell.statePath("welcome.json")
        printErrors: false

        JsonAdapter {
            id: welcomeSettings

            property bool done: false
            property string goal: ""
            property string imeShortcut: "ctrl"
        }
    }

    // Give the state file a moment to load; when it is missing this is the first login.
    Timer {
        interval: 2500
        running: true
        onTriggered: {
            if (!welcomeSettings.done)
                root.openWelcome();
        }
    }

    function openWelcome() {
        launcherOpen = false;
        quickSettingsOpen = false;
        overlayScreen = focusedScreen;
        welcomeOpen = true;
    }

    // goal: "basics" or "web" opens that in a terminal; "" or "explore" just closes.
    function finishWelcome(goal) {
        welcomeSettings.done = true;
        if (goal !== "")
            welcomeSettings.goal = goal;
        welcomeStore.writeAdapter();
        welcomeOpen = false;

        if (goal === "basics")
            openTerminal("robinctl learn");
        else if (goal === "web")
            openTerminal("robinctl lab info web");
    }

    // 한/영 always toggles with the Hangul key (Right Alt, see robinos.lua). The
    // extra shortcut is "ctrl" (Ctrl+Space), "shift" (Shift+Space) or "none".
    // Rewrites ~/.config/fcitx5/config (the copy from /etc/skel) and reloads fcitx5.
    function setImeShortcut(key) {
        const extra = { "ctrl": "Control+space", "shift": "Shift+space" }[key] ?? "";
        const lines = ["[Hotkey]", "EnumerateWithTriggerKeys=True", "", "[Hotkey/TriggerKeys]", "0=Hangul"];
        if (extra !== "")
            lines.push("1=" + extra);
        lines.push("", "[Behavior]", "ShareInputState=All");

        const file = "\"${XDG_CONFIG_HOME:-$HOME/.config}/fcitx5/config\"";
        const script = "f=" + file + "; mkdir -p \"${f%/*}\" && printf '%s\\n' "
            + lines.map(line => "'" + line + "'").join(" ") + " > \"$f\" && fcitx5-remote -r";
        Quickshell.execDetached(["sh", "-c", script]);

        welcomeSettings.imeShortcut = key;
        welcomeStore.writeAdapter();
    }

    function focusWorkspace(id) {
        Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.focus({ workspace = " + id + " })" : "workspace " + id);
    }

    // ---- Windows-style minimize and show desktop ----
    // A minimized window moves to a hidden special workspace. The dock keeps showing
    // it as running, and a click on the app (or Super+D again) brings it back.

    readonly property string minimizedWorkspace: "special:minimized"
    // Window address -> workspace it was minimized from
    property var restoreTo: ({})
    // Windows that Super+D hid, brought back by the next Super+D
    property var desktopHidden: []

    // Hyprland's windows (HyprlandToplevel): they know their workspace, unlike Wayland's
    readonly property var windows: Hyprland.toplevels.values

    function appIdOf(win) {
        return win?.wayland?.appId ?? win?.lastIpcObject?.class ?? "";
    }

    function isMinimized(win) {
        return win?.workspace?.name === minimizedWorkspace;
    }

    function windowsOf(appIds) {
        const out = [];
        for (let i = 0; i < windows.length; i++) {
            if (appIds.indexOf(appIdOf(windows[i])) !== -1)
                out.push(windows[i]);
        }
        return out;
    }

    function selector(win) {
        return "address:0x" + win.address;
    }

    function moveWindow(win, workspace) {
        Hyprland.dispatch(Hyprland.usingLua
            ? "hl.dsp.window.move({ workspace = " + JSON.stringify(workspace) + ", follow = false, window = \"" + selector(win) + "\" })"
            : "movetoworkspacesilent " + workspace + "," + selector(win));
    }

    function focusWindow(win) {
        Hyprland.dispatch(Hyprland.usingLua
            ? "hl.dsp.focus({ window = \"" + selector(win) + "\" })"
            : "focuswindow " + selector(win));
    }

    function minimize(win) {
        if (!win || isMinimized(win))
            return;
        const restore = Object.assign({}, restoreTo);
        restore[win.address] = win.workspace?.name ?? "";
        restoreTo = restore;
        moveWindow(win, minimizedWorkspace);
    }

    function restore(win, focus) {
        if (!win)
            return;
        if (isMinimized(win)) {
            // Back where it was, or to the workspace on screen if that is unknown
            let target = restoreTo[win.address] ?? "";
            if (target === "" || target.startsWith("special:"))
                target = Hyprland.focusedMonitor?.activeWorkspace?.name ?? "1";
            moveWindow(win, target);
        }
        if (focus)
            focusWindow(win);
    }

    // What a click on an app in the dock does, like the Windows taskbar: open the app,
    // bring its window to the front, minimize it when it already is in front, or
    // restore it when it is minimized. Several windows take turns.
    function toggleApp(appIds, command) {
        const wins = windowsOf(appIds);
        if (wins.length === 0) {
            if (command)
                Quickshell.execDetached(command);
            return;
        }
        const shown = wins.filter(w => !isMinimized(w));
        const active = shown.findIndex(w => w.activated);
        if (active !== -1) {
            if (shown.length > 1)
                focusWindow(shown[(active + 1) % shown.length]);
            else
                minimize(shown[active]);
        } else if (shown.length > 0) {
            focusWindow(shown[0]);
        } else {
            restore(wins[wins.length - 1], true);
        }
    }

    // Super+D: hide every window on the workspace on screen; pressed again with
    // nothing shown, bring back the ones it hid.
    function toggleDesktop() {
        const workspace = Hyprland.focusedMonitor?.activeWorkspace?.name ?? "";
        const all = toArray(windows);
        const shown = all.filter(w => w.workspace?.name === workspace);
        if (shown.length > 0) {
            desktopHidden = shown.map(w => w.address);
            for (const win of shown)
                minimize(win);
            return;
        }
        const back = all.filter(w => desktopHidden.indexOf(w.address) !== -1 && isMinimized(w));
        desktopHidden = [];
        for (let i = 0; i < back.length; i++)
            restore(back[i], i === back.length - 1);
    }

    // ---- Clock ----

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property var weekdays: ["일", "월", "화", "수", "목", "금", "토"]

    function pad(n) {
        return n < 10 ? "0" + n : "" + n;
    }

    // "10월 7일 (수) 오후 2:41"
    readonly property string clockText: {
        const d = clock.date;
        const h = d.getHours();
        const h12 = h % 12 === 0 ? 12 : h % 12;
        return (d.getMonth() + 1) + "월 " + d.getDate() + "일 (" + weekdays[d.getDay()] + ") "
            + (h < 12 ? "오전 " : "오후 ") + h12 + ":" + pad(d.getMinutes());
    }

    // ---- Audio ----

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool audioReady: sink?.audio !== undefined && sink?.audio !== null
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string volumeIcon: (muted || volume <= 0.001) ? "volume-x" : volume < 0.5 ? "volume-low" : "volume"

    function setVolume(value) {
        if (!audioReady)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute() {
        if (audioReady)
            sink.audio.muted = !sink.audio.muted;
    }

    // ---- Network and Bluetooth ----

    readonly property var wifiDevice: findIn(Networking.devices.values, d => d.type === DeviceType.Wifi)
    readonly property var wiredDevice: findIn(Networking.devices.values, d => d.type === DeviceType.Wired && d.connected)
    readonly property var wifiNetwork: wifiDevice ? findIn(wifiDevice.networks.values, n => n.connected) : null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool online: wiredDevice !== null || (wifiDevice?.connected ?? false)
    readonly property string netIcon: wiredDevice ? "network" : (!wifiEnabled ? "wifi-off" : "wifi")
    readonly property string netLabel: {
        if (wiredDevice)
            return "유선 연결됨";
        if (!wifiDevice)
            return "장치 없음";
        if (!wifiEnabled)
            return "꺼짐";
        return wifiNetwork?.name ?? "연결 안 됨";
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: btAdapter?.enabled ?? false

    function toggleBluetooth() {
        if (btAdapter)
            btAdapter.enabled = !btAdapter.enabled;
    }

    // ---- Korean input method (fcitx5-remote prints 2 when Hangul is active) ----

    property bool hangul: false

    Process {
        id: imeProc
        command: ["fcitx5-remote"]
        stdout: StdioCollector {
            id: imeOut
            onStreamFinished: root.hangul = imeOut.text.trim() === "2"
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!imeProc.running)
                imeProc.running = true;
        }
    }

    function toggleIme() {
        Quickshell.execDetached(["fcitx5-remote", "-t"]);
        root.hangul = !root.hangul;
    }

    // ---- Backlight (hidden on machines without one, e.g. most VMs) ----

    property bool hasBacklight: false
    property real brightness: 1
    property real pendingBrightness: -1

    Process {
        id: brightRead
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        stdout: StdioCollector {
            id: brightOut
            onStreamFinished: {
                const parts = brightOut.text.trim().split(",");
                if (parts.length >= 5) {
                    root.hasBacklight = true;
                    root.brightness = parseInt(parts[3]) / 100;
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.hasBacklight = false;
        }
    }

    Timer {
        id: brightWrite
        interval: 60
        onTriggered: {
            if (root.pendingBrightness < 0)
                return;
            Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set",
                                     Math.round(root.pendingBrightness * 100) + "%"]);
            root.pendingBrightness = -1;
        }
    }

    function refreshBrightness() {
        if (!brightRead.running)
            brightRead.running = true;
    }

    function setBrightness(value) {
        brightness = Math.max(0.05, Math.min(1, value));
        pendingBrightness = brightness;
        if (!brightWrite.running)
            brightWrite.start();
    }

    // ---- Local web lab (labs/web/docker-compose.yml) ----

    property bool labRunning: false

    // Users aren't in the docker group (robinctl lab asks for sudo), so `docker ps`
    // doesn't work here. Docker runs a docker-proxy for each published port;
    // look for the lab's ports instead.
    Process {
        id: labProc
        command: ["pgrep", "-f", "docker-proxy .*-host-port (3000|8080)( |$)"]
        onExited: (exitCode, exitStatus) => root.labRunning = exitCode === 0
    }

    function refreshLab() {
        if (!labProc.running)
            labProc.running = true;
    }

    // ---- Learning progress (robinctl learn) ----

    // LEARN_COUNT in bin/robinctl (scripts/test-robinctl.sh checks they agree)
    readonly property int learnTotal: 25
    property int learnDone: 0

    function refreshLearn() {
        learnFile.reload();
    }

    FileView {
        id: learnFile

        // robinctl writes the number of each finished mission here, one per line
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/robinos/learn/done"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const numbers = learnFile.text().split("\n").map(line => line.trim()).filter(line => /^[0-9]+$/.test(line));
            root.learnDone = new Set(numbers).size;
        }
        onLoadFailed: root.learnDone = 0
    }

    // ---- Host name ----

    FileView {
        id: hostFile
        path: "/etc/hostname"
        printErrors: false
        onLoaded: {
            const name = hostFile.text().trim();
            if (name.length > 0)
                root.hostName = name;
        }
    }

    // ---- Actions ----

    function launch(command) {
        Quickshell.execDetached(command);
    }

    // Runs a shell snippet in a floating foot window and waits for Enter before closing.
    function runInTerminal(script) {
        Quickshell.execDetached(["foot", "--app-id=robinos-float", "--title=RobinOS", "sh", "-c",
                                 script + "; printf '\\n\\033[2mEnter를 누르면 창이 닫혀요\\033[0m'; read _"]);
    }

    // Opens a regular terminal that runs a command first and then stays at the prompt.
    // ROBINOS_NO_GREETING keeps ~/.bashrc from printing fastfetch over the output.
    function openTerminal(script) {
        Quickshell.execDetached(["foot", "env", "ROBINOS_NO_GREETING=1", "bash", "-c", script + "; exec bash"]);
    }

    function openUrl(url) {
        Quickshell.execDetached(["xdg-open", url]);
    }

    function lock() {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    function logout() {
        Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exit()" : "exit");
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function powerOff() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
}
