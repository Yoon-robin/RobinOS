import QtQuick
import Quickshell

// Win+X like Windows' quick link menu (the Start button's right click): the system
// tools people reach for, in one short list above the dock's launcher button.
// Opened with Super+X or a right click on that button (ShellState.openQuickLinks).
PopupMenu {
    id: root

    open: ShellState.quickLinksOpen
    layerName: "robinos-quicklinks"
    // Above the dock's launcher button when it reported where it is
    at: Qt.point(ShellState.quickLinksX - 24, height - 92)
    upward: true
    onDismiss: ShellState.quickLinksOpen = false

    // The installed-system-only apps show up once they are there
    items: {
        // Read so the list is made again after the background scan of desktop entries
        const scanned = DesktopEntries.applications.values.length;
        const has = id => scanned >= 0 && !!DesktopEntries.byId(id);
        return [
            { icon: "terminal", title: "터미널", run: () => Quickshell.execDetached(["foot"]) },
            { icon: "activity", title: "작업 관리자", hint: "Ctrl+Shift+Esc", run: () => Quickshell.execDetached(["missioncenter"]) },
            { icon: "folder", title: "파일 탐색기", hint: "Win+E", run: () => Quickshell.execDetached(["nautilus", "--new-window"]) },
            { icon: "sliders", title: "설정", hint: "Win+I", run: () => ShellState.toggleQuickSettings(null) },
            { icon: "wifi", title: "네트워크 연결", run: () => ShellState.openDetail("wifi") },
            { icon: "volume", title: "소리", run: () => ShellState.openDetail("sound") }
        ].concat(has("org.gnome.DiskUtility") ? [{ icon: "hard-drive", title: "디스크 관리", run: () => Quickshell.execDetached(["gnome-disks"]) }] : [])
            .concat(has("org.gnome.baobab") ? [{ icon: "hard-drive", title: "저장소", run: () => Quickshell.execDetached(["baobab"]) }] : [])
            .concat([
                { icon: "activity", title: "시스템 점검", hint: "robinctl doctor", run: () => ShellState.runInTerminal("robinctl doctor") },
                { icon: "shield", title: "보안 점검", hint: "robinctl audit", run: () => ShellState.runInTerminal("robinctl audit") },
                { icon: "file", title: "이벤트 뷰어", hint: "journalctl", run: () => ShellState.showCommand(ShellState.adminCommands.logs) },
                { separator: true },
                { icon: "lock", title: "화면 잠금", hint: "Win+L", run: () => ShellState.lock() },
                { icon: "power", title: "종료 또는 로그아웃", run: () => ShellState.openPowerMenu() }
            ]);
    }
}
