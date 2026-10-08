import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// RobinOS shell entry point. Started by Hyprland: qs -p /usr/share/robinos/shell
ShellRoot {
    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen

            required property var modelData

            Wallpaper {
                modelData: perScreen.modelData
            }

            Bar {
                modelData: perScreen.modelData
            }

            Dock {
                modelData: perScreen.modelData
            }
        }
    }

    Launcher {}

    QuickSettings {}

    Calendar {}

    Toasts {}

    Osd {}

    Welcome {}

    Installer {}

    // Bound in robinos.lua with hl.dsp.global("robinos:<name>")
    GlobalShortcut {
        appid: "robinos"
        name: "launcher"
        description: "앱 런처 열기/닫기"
        onPressed: ShellState.toggleLauncher()
    }

    GlobalShortcut {
        appid: "robinos"
        name: "calendar"
        description: "달력 열기/닫기"
        onPressed: ShellState.toggleCalendar(null)
    }

    GlobalShortcut {
        appid: "robinos"
        name: "clipboard"
        description: "클립보드 기록 열기/닫기"
        onPressed: ShellState.toggleClipboard()
    }

    GlobalShortcut {
        appid: "robinos"
        name: "quicksettings"
        description: "빠른 설정 열기/닫기"
        onPressed: ShellState.toggleQuickSettings(null)
    }

    GlobalShortcut {
        appid: "robinos"
        name: "notifications"
        description: "알림 모두 지우기"
        onPressed: Notifs.clearAll()
    }

    GlobalShortcut {
        appid: "robinos"
        name: "desktop"
        description: "바탕 화면 보기 (다시 누르면 창이 돌아와요)"
        onPressed: ShellState.toggleDesktop()
    }

    // qs ipc -p /usr/share/robinos/shell call shell <function>
    IpcHandler {
        target: "shell"

        function launcher(): void {
            ShellState.toggleLauncher();
        }

        function quickSettings(): void {
            ShellState.toggleQuickSettings(null);
        }

        function setDark(dark: bool): void {
            Theme.setDark(dark);
        }

        function welcome(): void {
            ShellState.openWelcome();
        }

        function installer(): void {
            ShellState.openInstaller();
        }

        // The dock's click on an app: open, bring to front, minimize or restore
        function toggleApp(appId: string): void {
            ShellState.toggleApp([appId], null);
        }

        function toggleDesktop(): void {
            ShellState.toggleDesktop();
        }
    }
}
