import QtQuick
import Quickshell

// The desktop's right-click menu, like Windows': a terminal here, the wallpaper,
// the display settings (scale, brightness, night light in the quick settings) and
// the shortcut list. Opened from Wallpaper.qml with ShellState.openDesktopMenu.
PopupMenu {
    open: ShellState.desktopMenuOpen
    layerName: "robinos-desktopmenu"
    at: ShellState.desktopMenuAt
    onDismiss: ShellState.desktopMenuOpen = false

    items: [
        { icon: "terminal", title: "터미널 열기", hint: "Win+Enter", run: () => Quickshell.execDetached(["foot"]) },
        { icon: "folder", title: "파일 탐색기", hint: "Win+E", run: () => Quickshell.execDetached(["nautilus", "--new-window"]) },
        { separator: true },
        { icon: "image", title: "배경화면 바꾸기", run: () => ShellState.chooseWallpaper() }
    ].concat(ShellState.wallpaperPath !== "" ? [{ icon: "rotate-ccw", title: "기본 배경화면으로", run: () => ShellState.resetWallpaper() }] : [])
        .concat([
            { icon: "monitor", title: "디스플레이 설정", hint: "배율·밝기", run: () => ShellState.toggleQuickSettings(null) },
            { separator: true },
            { icon: "keyboard", title: "단축키 보기", hint: "Win+F1", run: () => ShellState.toggleShortcuts() }
        ])
}
