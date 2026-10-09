pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower

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
            property bool nightLight: false
            // Desktop entry ids pinned to the dock with a right click (Dock.qml)
            property list<string> dockPins: []
            // Apps opened from the launcher, newest first (Launcher.qml's 최근에 연 앱)
            property list<string> recentApps: []
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

    // The launcher also shows the clipboard history (Win+V) and emoji (Win+.)
    property bool launcherClipboard: false
    property bool launcherEmoji: false

    function toggleLauncher() {
        if (welcomeOpen)
            return;
        if (launcherOpen) {
            launcherOpen = false;
            return;
        }
        detailPanel = "";
        taskViewOpen = false;
        quickSettingsOpen = false;
        calendarOpen = false;
        overlayScreen = focusedScreen;
        launcherClipboard = false;
        launcherEmoji = false;
        launcherOpen = true;
    }

    function toggleClipboard() {
        if (welcomeOpen)
            return;
        if (launcherOpen) {
            launcherOpen = false;
            return;
        }
        detailPanel = "";
        taskViewOpen = false;
        quickSettingsOpen = false;
        calendarOpen = false;
        overlayScreen = focusedScreen;
        launcherClipboard = true;
        launcherEmoji = false;
        launcherOpen = true;
    }

    // Win+. like Windows' emoji panel: pick one and it is typed where you were
    function toggleEmoji() {
        if (welcomeOpen)
            return;
        if (launcherOpen) {
            launcherOpen = false;
            return;
        }
        detailPanel = "";
        taskViewOpen = false;
        quickSettingsOpen = false;
        calendarOpen = false;
        overlayScreen = focusedScreen;
        launcherClipboard = false;
        launcherEmoji = true;
        launcherOpen = true;
    }

    function toggleQuickSettings(screen) {
        if (welcomeOpen)
            return;
        if (quickSettingsOpen) {
            quickSettingsOpen = false;
            return;
        }
        detailPanel = "";
        taskViewOpen = false;
        launcherOpen = false;
        calendarOpen = false;
        overlayScreen = screen ?? focusedScreen;
        quickSettingsOpen = true;
    }

    // Win+X: the quick link menu (QuickLinks.qml) above the dock's launcher button,
    // whose left edge on screen the dock keeps here
    property bool quickLinksOpen: false
    property real quickLinksX: 0

    function toggleQuickLinks() {
        if (welcomeOpen)
            return;
        if (quickLinksOpen) {
            quickLinksOpen = false;
            return;
        }
        launcherOpen = false;
        quickSettingsOpen = false;
        calendarOpen = false;
        notifCenterOpen = false;
        detailPanel = "";
        taskViewOpen = false;
        overlayScreen = focusedScreen;
        quickLinksOpen = true;
    }

    // Alt+F4 on the desktop (robinos.lua): the quick settings open on their power menu
    property bool powerMenuRequested: false

    function openPowerMenu() {
        if (welcomeOpen)
            return;
        powerMenuRequested = true;
        if (quickSettingsOpen)
            quickSettingsOpen = false;
        toggleQuickSettings(null);
    }

    // Month calendar under the bar's clock (Calendar.qml), like Windows' clock flyout
    property bool calendarOpen: false

    function toggleCalendar(screen) {
        if (welcomeOpen)
            return;
        if (calendarOpen) {
            calendarOpen = false;
            return;
        }
        detailPanel = "";
        taskViewOpen = false;
        launcherOpen = false;
        quickSettingsOpen = false;
        overlayScreen = screen ?? focusedScreen;
        calendarOpen = true;
    }

    // Notifications since login under the bell (NotificationCenter.qml, Super+N)
    property bool notifCenterOpen: false

    function toggleNotifCenter() {
        if (welcomeOpen)
            return;
        if (notifCenterOpen) {
            notifCenterOpen = false;
            return;
        }
        launcherOpen = false;
        quickSettingsOpen = false;
        calendarOpen = false;
        detailPanel = "";
        taskViewOpen = false;
        shortcutsOpen = false;
        overlayScreen = focusedScreen;
        notifCenterOpen = true;
    }

    // The list behind a quick settings arrow: "wifi" or "bluetooth"
    // (ConnectPanel.qml), "sound" (SoundPanel.qml) or "" when closed
    property string detailPanel: ""

    function openDetail(name) {
        if (welcomeOpen)
            return;
        // From a tile: stay on the screen the quick settings were on
        if (!quickSettingsOpen)
            overlayScreen = focusedScreen;
        launcherOpen = false;
        quickSettingsOpen = false;
        calendarOpen = false;
        notifCenterOpen = false;
        shortcutsOpen = false;
        detailPanel = ["wifi", "bluetooth", "sound"].includes(name) ? name : "wifi";
    }

    // Win+Tab: every window on every workspace (TaskView.qml)
    property bool taskViewOpen: false

    function toggleTaskView() {
        if (welcomeOpen)
            return;
        if (taskViewOpen) {
            taskViewOpen = false;
            return;
        }
        launcherOpen = false;
        quickSettingsOpen = false;
        calendarOpen = false;
        notifCenterOpen = false;
        shortcutsOpen = false;
        detailPanel = "";
        overlayScreen = focusedScreen;
        taskViewOpen = true;
    }

    // Every shortcut on one card (Shortcuts.qml, Super+F1)
    property bool shortcutsOpen: false

    function toggleShortcuts() {
        if (welcomeOpen)
            return;
        if (shortcutsOpen) {
            shortcutsOpen = false;
            return;
        }
        launcherOpen = false;
        quickSettingsOpen = false;
        calendarOpen = false;
        detailPanel = "";
        taskViewOpen = false;
        overlayScreen = focusedScreen;
        shortcutsOpen = true;
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

    // ---- Learning center (LearnCenter.qml) ----

    property bool learnCenterOpen: false

    function openLearnCenter() {
        launcherOpen = false;
        quickSettingsOpen = false;
        calendarOpen = false;
        // Already open (maybe behind other windows): map it again to bring it forward
        if (learnCenterOpen)
            learnCenterOpen = false;
        learnCenterOpen = true;
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
        calendarOpen = false;
        overlayScreen = focusedScreen;
        welcomeOpen = true;
    }

    // goal: "basics" opens the learning center, "web" the web lab guide in a terminal;
    // "" or "explore" just closes.
    function finishWelcome(goal) {
        welcomeSettings.done = true;
        if (goal !== "")
            welcomeSettings.goal = goal;
        welcomeStore.writeAdapter();
        welcomeOpen = false;

        if (goal === "basics")
            openLearnCenter();
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

    // Windows' virtual desktops: Win+Ctrl+D (and the task view's "새 작업 공간") goes
    // to the first empty workspace, Win+Ctrl+F4 closes this one by moving its windows
    // to the workspace on the left (on the right for the first one), like Windows.
    function newWorkspace() {
        const used = toArray(Hyprland.workspaces.values).map(w => w.id);
        let id = 1;
        while (used.indexOf(id) !== -1)
            id++;
        focusWorkspace(id);
    }

    function closeWorkspace() {
        const current = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 0;
        const others = toArray(Hyprland.workspaces.values).map(w => w.id).filter(id => id > 0 && id !== current);
        if (current <= 0 || others.length === 0)
            return;
        const left = others.filter(id => id < current);
        const target = left.length > 0 ? Math.max(...left) : Math.min(...others);
        for (const win of toArray(windows)) {
            if (win.workspace?.id === current)
                moveWindow(win, target);
        }
        focusWorkspace(target);
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

    // The shell's own windows all carry Quickshell's app id; their titles tell them
    // apart, so the dock shows the installer and the learning center as two apps
    readonly property var shellWindowIds: ({
            "RobinOS 설치": "robinos-installer",
            "학습 센터": "robinos-learn"
        })

    function appIdOf(win) {
        const appId = win?.wayland?.appId ?? win?.lastIpcObject?.class ?? "";
        if (appId === "org.quickshell" || appId === "quickshell")
            return shellWindowIds[win?.title ?? ""] ?? appId;
        return appId;
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

    // ---- Alt+Tab (AltTab.qml) ----

    // Window addresses, the most recently focused first, like Windows' Alt+Tab order
    property var focusOrder: []

    Connections {
        target: Hyprland

        function onActiveToplevelChanged() {
            const address = Hyprland.activeToplevel?.address ?? "";
            if (address !== "")
                root.focusOrder = [address].concat(root.focusOrder.filter(a => a !== address)).slice(0, 50);
        }
    }

    // Where a window comes in Alt+Tab: windows never focused since login go last
    function switcherRank(win) {
        const i = focusOrder.indexOf(win.address);
        return i === -1 ? focusOrder.length : i;
    }

    // The windows Alt+Tab offers: this workspace's and the minimized ones, last used first
    function switcherWindows() {
        const workspace = Hyprland.focusedMonitor?.activeWorkspace?.name ?? "";
        return toArray(windows).filter(w => w.workspace?.name === workspace || isMinimized(w))
            .sort((a, b) => switcherRank(a) - switcherRank(b));
    }

    function switchTo(win) {
        restore(win, true);
        Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.window.bring_to_top()" : "bringactivetotop");
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
    readonly property var now: clock.date

    // "2026년 10월 8일 목요일", the calendar's heading
    readonly property string dateLong: {
        const d = clock.date;
        return d.getFullYear() + "년 " + (d.getMonth() + 1) + "월 " + d.getDate() + "일 " + weekdays[d.getDay()] + "요일";
    }

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

    // Windows' 비행기 모드: the Wi-Fi and Bluetooth radios off (a cable stays connected).
    // NetworkManager and BlueZ remember the radios, so it lasts across reboots.
    readonly property bool airplane: !wifiEnabled && !btEnabled

    function toggleAirplane() {
        const on = !airplane;
        Networking.wifiEnabled = !on;
        if (btAdapter)
            btAdapter.enabled = !on;
    }

    // ---- Night light, like Windows' 야간 모드: hyprsunset warms the screen ----

    readonly property bool nightLight: desktopSettings.nightLight

    // ---- Apps opened from the launcher lately ----

    readonly property var recentApps: desktopSettings.recentApps

    function noteRecentApp(id) {
        if (!id)
            return;
        desktopSettings.recentApps = [id].concat(recentApps.filter(app => app !== id)).slice(0, 8);
        desktopStore.writeAdapter();
    }

    // ---- Apps pinned to the dock, like pinning to the Windows taskbar ----

    readonly property var dockPins: desktopSettings.dockPins

    // The app's own name ("계산기") for a desktop entry id, when the caller has none
    function appName(id, name) {
        return name || (DesktopEntries.byId(id)?.name ?? id);
    }

    function pinToDock(id, name) {
        if (!id || dockPins.indexOf(id) !== -1)
            return;
        desktopSettings.dockPins = dockPins.concat([id]);
        desktopStore.writeAdapter();
        Quickshell.execDetached(["notify-send", "-a", "RobinOS", "독에 고정했어요", appName(id, name) + " · 다시 오른쪽 클릭하면 고정을 풀어요"]);
    }

    function unpinFromDock(id, name) {
        if (dockPins.indexOf(id) === -1)
            return;
        desktopSettings.dockPins = dockPins.filter(pin => pin !== id);
        desktopStore.writeAdapter();
        Quickshell.execDetached(["notify-send", "-a", "RobinOS", "독에서 뺐어요", appName(id, name)]);
    }
    // Hyprland changes the colors through the graphics driver (KMS CTM), which VM
    // graphics (QEMU, VMware, Hyper-V) don't offer; the tile says so there
    property bool inVm: false

    Process {
        command: ["systemd-detect-virt", "--vm", "--quiet"]
        running: true
        onExited: (exitCode, exitStatus) => root.inVm = exitCode === 0
    }

    // Stopping hyprsunset gives the screen its normal colors back
    Process {
        running: desktopSettings.nightLight
        command: ["hyprsunset", "--temperature", "4500"]
    }

    function toggleNightLight() {
        desktopSettings.nightLight = !desktopSettings.nightLight;
        desktopStore.writeAdapter();
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

    // ---- Wallpaper picture ("배경으로 설정", desktop/bin/robinos-wallpaper-portal) ----

    // Empty for the RobinOS wallpaper that Wallpaper.qml draws
    property string wallpaperPath: ""
    // Bumped on every change: the portal keeps the copy under one name
    property int wallpaperVersion: 0

    FileView {
        id: wallpaperFile

        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/robinos/wallpaper"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.wallpaperPath = wallpaperFile.text().trim();
            root.wallpaperVersion++;
        }
        onLoadFailed: root.wallpaperPath = ""
    }

    // The Wallpaper portal asks before an app sets the wallpaper for the first time.
    // Apps outside a sandbox (Files, Image Viewer: app id "") could write the
    // state file above anyway, so they get a standing yes; Flatpak apps still ask.
    Timer {
        interval: 3000
        running: true
        onTriggered: Quickshell.execDetached(["gdbus", "call", "--session",
            "--dest", "org.freedesktop.impl.portal.PermissionStore",
            "--object-path", "/org/freedesktop/impl/portal/PermissionStore",
            "--method", "org.freedesktop.impl.portal.PermissionStore.SetPermission",
            "wallpaper", "true", "wallpaper", "", "['yes']"])
    }

    function resetWallpaper() {
        wallpaperPath = "";
        Quickshell.execDetached(["rm", "-f", wallpaperFile.path]);
    }

    // Files opens on the Pictures folder; right-click a picture for "배경으로 설정"
    function chooseWallpaper() {
        Quickshell.execDetached(["sh", "-c", "exec nautilus --new-window \"$(xdg-user-dir PICTURES)\""]);
        Quickshell.execDetached(["notify-send", "-a", "RobinOS", "배경화면 바꾸기",
                                 "사진을 오른쪽 버튼으로 누르고 \"배경으로 설정\"을 골라요. 이미지 보기에서는 메뉴의 \"백그라운드로 설정\"이에요."]);
    }

    // ---- Display scale, like Windows' "배율" (quick settings) ----
    // Applied right away through hyprctl and saved as "output scale" lines that
    // robinos.lua (and robinos-vm-display in VMs) apply at the next login.

    readonly property var scaleOptions: [1, 1.25, 1.5, 1.75, 2]
    readonly property real displayScale: Hyprland.focusedMonitor?.scale ?? 1
    property var savedScales: ({})

    FileView {
        id: scaleFile

        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/robinos/display-scale"
        printErrors: false
        onLoaded: {
            const scales = {};
            for (const line of scaleFile.text().split("\n")) {
                const m = line.match(/^([A-Za-z0-9-]+)\s+([0-9.]+)$/);
                if (m)
                    scales[m[1]] = parseFloat(m[2]);
            }
            root.savedScales = scales;
        }
    }

    // Hyprland only reports the new scale on the next monitor query
    Timer {
        id: monitorRefresh
        interval: 500
        onTriggered: {
            Hyprland.refreshMonitors();
            Hyprland.refreshToplevels();
            floatingFit.restart();
        }
    }

    // Floating windows keep their place and size when the scale changes, so a
    // bigger scale can push them partly off the screen; those get centered
    Timer {
        id: floatingFit
        interval: 300
        onTriggered: {
            const screen = Hyprland.focusedMonitor?.lastIpcObject;
            if (!screen || !screen.scale)
                return;
            const right = screen.x + screen.width / screen.scale;
            const bottom = screen.y + screen.height / screen.scale;
            for (const win of root.windows) {
                const w = win.lastIpcObject;
                if (!w || !w.floating || w.monitor !== screen.id || root.isMinimized(win) || !w.at || !w.size)
                    continue;
                if (w.at[0] < screen.x || w.at[1] < screen.y || w.at[0] + w.size[0] > right || w.at[1] + w.size[1] > bottom)
                    Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.window.center({ window = \"" + root.selector(win) + "\" })"
                                                        : "centerwindow");
            }
        }
    }

    function setScale(scale) {
        const monitor = Hyprland.focusedMonitor;
        // Output names come from the kernel (eDP-1, HDMI-A-1, Virtual-1); anything
        // else stays out of the Lua that hyprctl runs
        if (!monitor || !/^[A-Za-z0-9-]+$/.test(monitor.name) || scaleOptions.indexOf(scale) === -1)
            return;
        // A VM screen keeps the size robinos-vm-display gave it
        const mode = monitor.name.startsWith("Virtual-") ? monitor.width + "x" + monitor.height : "preferred";
        Quickshell.execDetached(["hyprctl", "eval", "hl.monitor({ output = \"" + monitor.name + "\", mode = \"" + mode
                                 + "\", position = \"auto\", scale = " + scale + " })"]);
        const scales = Object.assign({}, savedScales);
        scales[monitor.name] = scale;
        savedScales = scales;
        scaleFile.setText(Object.keys(scales).map(name => name + " " + scales[name]).join("\n") + "\n");
        monitorRefresh.restart();
    }

    // ---- Low battery warning, like Windows at 10% and 5% ----
    // A critical notification stays until dismissed. Near empty, UPower's own
    // CriticalPowerAction puts the laptop to sleep or turns it off.

    readonly property var battery: UPower.displayDevice
    // The lowest level already warned about since the battery last charged
    property int batteryWarned: 100

    function checkBattery() {
        if (!battery.ready || !battery.isLaptopBattery)
            return;
        // Only real charging starts the warnings over; UPower briefly reports
        // "unknown" now and then, which would repeat the same warning
        if (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged) {
            batteryWarned = 100;
            return;
        }
        if (battery.state !== UPowerDeviceState.Discharging)
            return;
        const percent = Math.round(battery.percentage * 100);
        for (const level of [5, 10]) {
            if (percent <= level && batteryWarned > level) {
                batteryWarned = level;
                Quickshell.execDetached(["notify-send", "-a", "RobinOS", "-u", "critical", "-i", "battery-caution",
                                         "배터리가 " + percent + "% 남았어요",
                                         level === 5 ? "지금 전원을 연결하세요. 곧 컴퓨터가 잠들거나 꺼져요."
                                                     : "전원을 연결하세요. 빠른 설정에서 전원 모드를 절전으로 바꾸면 더 오래 써요."]);
                break;
            }
        }
    }

    Connections {
        target: root.battery

        function onPercentageChanged() {
            root.checkBattery();
        }

        function onStateChanged() {
            root.checkBattery();
        }

        function onReadyChanged() {
            root.checkBattery();
        }
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

    // ---- Updates, like the Windows Update dot ----
    // checkupdates (pacman-contrib) looks with its own copy of the package
    // database, so it never locks pacman. The live session doesn't check.

    property int updateCount: 0
    property real lastUpdateCheck: 0

    // At most every ten minutes, unless the timer asks
    function checkUpdates(force) {
        if (isLive || updateProc.running)
            return;
        if (!force && Date.now() - lastUpdateCheck < 10 * 60 * 1000)
            return;
        lastUpdateCheck = Date.now();
        updateProc.running = true;
    }

    Process {
        id: updateProc

        command: ["sh", "-c", "checkupdates 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            id: updateOut

            onStreamFinished: root.updateCount = parseInt(updateOut.text.trim()) || 0
        }
    }

    // First look three minutes after login (not to slow the start), then every three hours
    Timer {
        interval: 3 * 60 * 1000
        running: true
        onTriggered: {
            root.checkUpdates(true);
            interval = 3 * 60 * 60 * 1000;
            restart();
        }
    }

    // ---- Learning progress (robinctl learn) ----

    // LEARN_COUNT in bin/robinctl (scripts/test-robinctl.sh checks they agree)
    readonly property int learnTotal: 40
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

    // Windows admin tools' jobs as commands (the launcher's Windows names, Win+X)
    readonly property var adminCommands: ({
            logs: "journalctl -b -p warning --no-pager | tail -n 40",
            services: "systemctl list-units --type=service --state=running --no-pager",
            timers: "systemctl list-timers --no-pager",
            devices: "lspci -k && lsusb",
            sysinfo: "fastfetch"
        })

    // The Linux command behind a Windows tool (이벤트 뷰어 → journalctl), printed
    // before it runs so the terminal teaches it. Fixed commands only, no quotes.
    function showCommand(command) {
        openTerminal("printf '\\033[2m$ %s\\033[0m\\n' '" + command + "'; " + command);
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
