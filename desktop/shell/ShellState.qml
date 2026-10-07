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

    function toggleLauncher() {
        if (launcherOpen) {
            launcherOpen = false;
            return;
        }
        quickSettingsOpen = false;
        overlayScreen = focusedScreen;
        launcherOpen = true;
    }

    function toggleQuickSettings(screen) {
        if (quickSettingsOpen) {
            quickSettingsOpen = false;
            return;
        }
        launcherOpen = false;
        overlayScreen = screen ?? focusedScreen;
        quickSettingsOpen = true;
    }

    function focusWorkspace(id) {
        Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.focus({ workspace = " + id + " })" : "workspace " + id);
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

    Process {
        id: labProc
        command: ["docker", "ps", "--filter", "name=robinos-", "--format", "{{.Names}}"]
        stdout: StdioCollector {
            id: labOut
            onStreamFinished: root.labRunning = labOut.text.indexOf("robinos-") !== -1
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.labRunning = false;
        }
    }

    function refreshLab() {
        if (!labProc.running)
            labProc.running = true;
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
