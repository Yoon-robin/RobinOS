import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "keys.js" as Keyboard

// Notification center under the bar's bell (Win+N or a click on the bell), like
// Windows 11's: the notifications since login (Notifs.history), clear all, and
// Do Not Disturb. A click (or Tab + Enter) on a notification opens what it was
// about (Notifs.openEntry). Escape or a click outside closes it.
PanelWindow {
    id: root

    readonly property bool open: ShellState.notifCenterOpen
    property bool mapped: false
    property bool revealed: false

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
    WlrLayershell.namespace: "robinos-notifications"
    // Only while open: during the fade-out the keyboard already goes back, so a window
    // started from here (a terminal, an app) gets the focus (boot test, 2026-10-10)
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onOpenChanged: {
        if (open) {
            Notifs.unread = 0;
            mapped = true;
            Qt.callLater(() => {
                root.revealed = true;
                card.forceActiveFocus();
            });
        } else {
            revealed = false;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: Theme.dur
        onTriggered: {
            if (!root.open)
                root.mapped = false;
        }
    }

    function close() {
        ShellState.notifCenterOpen = false;
    }

    // "방금", "5분 전", "오후 3:12"
    function when(time) {
        const minutes = Math.floor((ShellState.now - time) / 60000);
        if (minutes < 1)
            return "방금";
        if (minutes < 60)
            return minutes + "분 전";
        const h = time.getHours();
        return (h < 12 ? "오전 " : "오후 ") + (h % 12 === 0 ? 12 : h % 12) + ":" + String(time.getMinutes()).padStart(2, "0");
    }

    // Click anywhere outside the card to close
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight + 6
        anchors.rightMargin: 8
        width: 360
        height: Math.min(content.implicitHeight + 28, parent.height - Theme.barHeight - 120)
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        opacity: root.revealed ? 1 : 0
        focus: true
        clip: true

        transform: Translate {
            y: root.revealed ? 0 : -6

            Behavior on y {
                NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic }
        }

        layer.enabled: !Theme.lowPower
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            shadowVerticalOffset: 12
        }

        Keys.onEscapePressed: root.close()

        // Keep clicks inside the card from closing it
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "알림"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                ActionButton {
                    visible: Notifs.history.length > 0
                    variant: "ghost"
                    implicitHeight: 28
                    text: "모두 지우기"
                    onClicked: Notifs.clearHistory()
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 18
                Layout.bottomMargin: 18
                visible: Notifs.history.length === 0
                horizontalAlignment: Text.AlignHCenter
                text: "새 알림이 없어요"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 13
            }

            // By index, so an entry keeps its live notification for Notifs.openEntry
            Repeater {
                model: Math.min(8, Notifs.history.length)

                // A new notification makes the rows again; keep Tab and Esc working
                onItemRemoved: (index, item) => {
                    if (item.activeFocus)
                        card.forceActiveFocus();
                }

                Rectangle {
                    id: item

                    required property int index
                    readonly property var modelData: Notifs.history[index]
                    readonly property bool openable: Notifs.canOpen(modelData)

                    Layout.fillWidth: true
                    implicitHeight: row.implicitHeight + 20
                    radius: Theme.radiusMd
                    color: openable && (area.containsMouse || item.activeFocus) ? Theme.secondary : Theme.raised
                    border.width: 1
                    border.color: Theme.border
                    activeFocusOnTab: openable

                    Accessible.role: openable ? Accessible.Button : Accessible.StaticText
                    Accessible.name: modelData.summary

                    function activate() {
                        if (!Notifs.canOpen(modelData))
                            return;
                        root.close();
                        Notifs.openEntry(modelData);
                    }

                    Keys.onPressed: event => {
                        if (Keyboard.activates(event)) {
                            item.activate();
                            event.accepted = true;
                        }
                    }

                    Behavior on color {
                        ColorAnimation { duration: Theme.durFast }
                    }

                    // A click opens what it was about (Windows does the same)
                    MouseArea {
                        id: area

                        anchors.fill: parent
                        enabled: item.openable
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: item.activate()
                    }

                    FocusRing {}

                    RowLayout {
                        id: row

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 10

                        Item {
                            Layout.alignment: Qt.AlignTop
                            implicitWidth: 28
                            implicitHeight: 28

                            IconImage {
                                visible: item.modelData.icon !== ""
                                anchors.fill: parent
                                source: item.modelData.icon
                            }

                            Rectangle {
                                visible: item.modelData.icon === ""
                                anchors.fill: parent
                                radius: 7
                                color: Theme.secondary

                                Icon {
                                    anchors.centerIn: parent
                                    name: "bell"
                                    size: 14
                                    color: Theme.fgSoft
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    Layout.fillWidth: true
                                    text: item.modelData.summary
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: root.when(item.modelData.time)
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: item.modelData.body
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }

                            Text {
                                visible: text !== ""
                                text: item.modelData.appName
                                color: Theme.subtle
                                font.family: Theme.font
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.border
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                spacing: 8

                Icon {
                    name: ShellState.dnd ? "bell-off" : "bell"
                    size: 15
                    color: Theme.muted
                }

                Text {
                    Layout.fillWidth: true
                    text: ShellState.dnd ? "방해 금지 켜짐 · 알림이 뜨지 않고 여기에만 쌓여요" : "방해 금지"
                    color: Theme.fgSoft
                    font.family: Theme.font
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                ActionButton {
                    variant: "outline"
                    implicitHeight: 28
                    text: ShellState.dnd ? "끄기" : "켜기"
                    onClicked: ShellState.dnd = !ShellState.dnd
                }
            }
        }
    }
}
