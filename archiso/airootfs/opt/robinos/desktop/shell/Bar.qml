import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower

// Top bar: logo, workspaces, focused app | clock | input method, status, notifications.
PanelWindow {
    id: bar

    required property var modelData

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "robinos-bar"

    readonly property var monitor: Hyprland.monitorFor(bar.screen)
    readonly property int activeWorkspace: monitor?.activeWorkspace?.id ?? 1
    readonly property int workspaceCount: {
        let highest = 5;
        const list = Hyprland.workspaces.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i].id > highest && list[i].id <= 9)
                highest = list[i].id;
        }
        return highest;
    }

    function occupied(id) {
        const ws = ShellState.findIn(Hyprland.workspaces.values, w => w.id === id);
        return ws !== null && ws.toplevels.values.length > 0;
    }

    readonly property string focusedApp: {
        const top = ToplevelManager.activeToplevel;
        if (!top || !top.activated)
            return "";
        // A minimized window stays "activated" when nothing else takes the focus
        const win = ShellState.findIn(ShellState.windows, w => w.wayland === top);
        if (win && ShellState.isMinimized(win))
            return "";
        // The shell's own windows (the installer) would read "Quickshell"
        if (top.appId === "" || top.appId === "org.quickshell")
            return top.title;
        DesktopEntries.applications.values; // re-evaluate after the background scan
        const entry = DesktopEntries.heuristicLookup(top.appId);
        return entry?.name ?? top.appId;
    }

    IdleInhibitor {
        window: bar
        enabled: ShellState.keepAwake
    }

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery.ready && battery.isLaptopBattery
    readonly property bool charging: battery.state === UPowerDeviceState.Charging
                                     || battery.state === UPowerDeviceState.FullyCharged

    Rectangle {
        anchors.fill: parent
        color: Theme.barBg

        Behavior on color {
            ColorAnimation { duration: Theme.dur }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.border
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        BarButton {
            label: "앱 런처"
            active: ShellState.launcherOpen
            onClicked: ShellState.toggleLauncher()

            Mark {}

            Text {
                text: "RobinOS"
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            implicitWidth: 1
            implicitHeight: 16
            color: Theme.border
        }

        Repeater {
            model: bar.workspaceCount

            Rectangle {
                id: ws

                required property int index
                readonly property int wsId: index + 1
                readonly property bool isActive: bar.activeWorkspace === wsId

                implicitWidth: 24
                implicitHeight: 24
                radius: Theme.radiusSm
                color: isActive ? Theme.secondary : wsMouse.containsMouse ? Theme.hover : "transparent"

                Accessible.role: Accessible.Button
                Accessible.name: "작업 공간 " + wsId

                Text {
                    anchors.centerIn: parent
                    text: ws.wsId
                    color: ws.isActive ? Theme.fg : bar.occupied(ws.wsId) ? Theme.fgSoft : Theme.subtle
                    font.family: Theme.mono
                    font.pixelSize: 12
                }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.focusWorkspace(ws.wsId)
                }
            }
        }

        Text {
            Layout.leftMargin: 10
            Layout.maximumWidth: 320
            visible: bar.focusedApp !== ""
            text: bar.focusedApp
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
    }

    Text {
        anchors.centerIn: parent
        text: ShellState.clockText
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: 13
        font.weight: Font.Medium
    }

    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        // 한/A indicator; click to switch
        Rectangle {
            implicitWidth: 24
            implicitHeight: 24
            radius: Theme.radiusSm
            color: imeMouse.containsMouse ? Theme.hover : "transparent"

            Accessible.role: Accessible.Button
            Accessible.name: ShellState.hangul ? "한글 입력 중" : "영문 입력 중"

            Rectangle {
                anchors.centerIn: parent
                width: 18
                height: 18
                radius: 4
                color: "transparent"
                border.width: 1
                border.color: Theme.borderStrong

                Text {
                    anchors.centerIn: parent
                    text: ShellState.hangul ? "한" : "A"
                    color: Theme.fgSoft
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }

            MouseArea {
                id: imeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.toggleIme()
            }
        }

        BarButton {
            label: "빠른 설정"
            padding: 10
            spacing: 10
            active: ShellState.quickSettingsOpen && ShellState.overlayScreen === bar.screen
            onClicked: ShellState.toggleQuickSettings(bar.screen)

            Icon {
                name: ShellState.netIcon
                color: ShellState.online || ShellState.wifiEnabled ? Theme.fgSoft : Theme.subtle
            }

            Icon {
                name: ShellState.volumeIcon
                color: Theme.fgSoft
            }

            RowLayout {
                visible: bar.hasBattery
                spacing: 6

                Item {
                    implicitWidth: 16
                    implicitHeight: 16

                    Icon {
                        name: bar.charging ? "battery-charging" : "battery"
                        color: Theme.fgSoft
                    }

                    // Fill level inside the battery outline (24px icon grid scaled to 16px)
                    Rectangle {
                        visible: !bar.charging
                        x: 4 * 16 / 24
                        y: 9 * 16 / 24
                        width: 12 * 16 / 24 * Math.max(0, Math.min(1, bar.battery.percentage))
                        height: 6 * 16 / 24
                        radius: 1
                        color: bar.battery.percentage < 0.2 ? Theme.destructive : Theme.fgSoft
                    }
                }

                Text {
                    text: Math.round(bar.battery.percentage * 100) + "%"
                    color: Theme.fgSoft
                    font.family: Theme.font
                    font.pixelSize: 13
                }
            }
        }

        Item {
            implicitWidth: 28
            implicitHeight: 28

            IconButton {
                anchors.fill: parent
                icon: ShellState.dnd ? "bell-off" : "bell"
                label: ShellState.dnd ? "방해 금지 끄기" : "방해 금지 켜기"
                onClicked: ShellState.dnd = !ShellState.dnd
            }

            Rectangle {
                visible: Notifs.count > 0
                x: 17
                y: 5
                width: 6
                height: 6
                radius: 3
                color: Theme.accent
                border.width: 1.5
                border.color: Theme.bg
            }
        }
    }
}
