import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "keys.js" as Keyboard

// Win+X like Windows' quick link menu (the Start button's right click): the system
// tools people reach for, in one short list above the dock's launcher button.
// Opened with Super+X or a right click on that button (ShellState.openQuickLinks).
PanelWindow {
    id: root

    readonly property bool open: ShellState.quickLinksOpen
    property bool mapped: false
    property int selected: 0

    // The installed-system-only apps show up once they are there
    readonly property var items: {
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
                { icon: "file", title: "이벤트 뷰어", hint: "journalctl", run: () => ShellState.openTerminal("journalctl -b -p warning --no-pager | tail -n 40") },
                { separator: true },
                { icon: "lock", title: "화면 잠금", hint: "Win+L", run: () => ShellState.lock() },
                { icon: "power", title: "종료 또는 로그아웃", run: () => ShellState.openPowerMenu() }
            ]);
    }
    readonly property var choices: items.filter(item => !item.separator)

    screen: ShellState.overlayScreen ?? Quickshell.screens[0]
    visible: mapped
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "robinos-quicklinks"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onOpenChanged: {
        if (open) {
            selected = 0;
            mapped = true;
            Qt.callLater(() => card.forceActiveFocus());
        } else {
            mapped = false;
        }
    }

    function close() {
        ShellState.quickLinksOpen = false;
    }

    function pick(item) {
        close();
        // After the menu lets go of the keyboard, so a new window gets the focus
        Qt.callLater(item.run);
    }

    // A click anywhere else closes it
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card

        // Above the dock's launcher button when it reported where it is
        x: Math.max(8, Math.min(parent.width - width - 8, ShellState.quickLinksX - 24))
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 92
        width: 260
        height: list.implicitHeight + 12
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        focus: true

        layer.enabled: !Theme.lowPower
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            shadowVerticalOffset: 12
        }

        Keys.onEscapePressed: root.close()
        Keys.onPressed: event => {
            const step = { [Qt.Key_Down]: 1, [Qt.Key_Tab]: 1, [Qt.Key_Up]: -1, [Qt.Key_Backtab]: -1 }[event.key];
            if (step !== undefined) {
                root.selected = (root.selected + step + root.choices.length) % root.choices.length;
                event.accepted = true;
            } else if (Keyboard.activates(event)) {
                root.pick(root.choices[root.selected]);
                event.accepted = true;
            }
        }

        // Keep clicks between the rows from closing it
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: list

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            spacing: 0

            // By index: the entries keep their functions, which a model copy would drop
            Repeater {
                model: root.items.length

                Item {
                    id: entry

                    required property int index
                    readonly property var modelData: root.items[index]
                    readonly property int choice: root.choices.indexOf(modelData)
                    readonly property bool chosen: choice === root.selected

                    Layout.fillWidth: true
                    implicitHeight: modelData.separator ? 9 : 34

                    Rectangle {
                        visible: entry.modelData.separator === true
                        anchors.centerIn: parent
                        width: parent.width - 12
                        height: 1
                        color: Theme.border
                    }

                    Rectangle {
                        visible: entry.modelData.separator !== true
                        anchors.fill: parent
                        radius: Theme.radiusMd
                        color: entry.chosen || rowMouse.containsMouse ? Theme.hover : "transparent"

                        Accessible.role: Accessible.MenuItem
                        Accessible.name: entry.modelData.title ?? ""

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Icon {
                                name: entry.modelData.icon ?? ""
                                size: 15
                                color: Theme.fgSoft
                            }

                            Text {
                                Layout.fillWidth: true
                                text: entry.modelData.title ?? ""
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }

                            Text {
                                text: entry.modelData.hint ?? ""
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selected = entry.choice
                            onClicked: root.pick(entry.modelData)
                        }
                    }
                }
            }
        }
    }
}
