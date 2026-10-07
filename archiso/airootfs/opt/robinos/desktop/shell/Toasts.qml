import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications

// Notification toasts (Sonner-style), bottom-right of the focused screen.
// Hidden while Do Not Disturb is on; the bell in the bar shows a dot instead.
PanelWindow {
    id: root

    screen: ShellState.focusedScreen
    visible: !ShellState.dnd && Notifs.count > 0
    anchors {
        bottom: true
        right: true
    }
    margins {
        bottom: 16
        right: 16
    }
    implicitWidth: 380
    implicitHeight: Math.max(1, stack.implicitHeight)
    // Stay clear of the dock and bar, but never push windows aside
    exclusiveZone: 0
    color: "transparent"
    mask: Region {
        item: stack
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "robinos-toasts"

    ColumnLayout {
        id: stack

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 8

        Repeater {
            model: Notifs.list

            Rectangle {
                id: toast

                required property var modelData
                readonly property var n: modelData
                readonly property string iconSource: Notifs.iconSource(n)
                readonly property bool critical: n.urgency === NotificationUrgency.Critical

                Layout.fillWidth: true
                implicitHeight: body.implicitHeight + 28
                radius: 12
                color: Theme.surface
                border.width: 1
                border.color: critical ? Theme.destructive : Theme.border

                layer.enabled: !Theme.lowPower
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Theme.shadow
                    shadowBlur: 0.8
                    shadowVerticalOffset: 8
                }

                Accessible.role: Accessible.AlertMessage
                Accessible.name: n.summary

                // Expire after the requested time (milliseconds; -1 = default 5s, 0 = never)
                Timer {
                    interval: toast.n.expireTimeout > 0 ? toast.n.expireTimeout : 5000
                    running: !toast.critical && toast.n.expireTimeout !== 0 && !hover.containsMouse && !ShellState.dnd
                    onTriggered: toast.n.expire()
                }

                MouseArea {
                    id: hover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const actions = toast.n.actions;
                        for (let i = 0; i < actions.length; i++) {
                            if (actions[i].identifier === "default") {
                                actions[i].invoke();
                                return;
                            }
                        }
                        toast.n.dismiss();
                    }
                }

                RowLayout {
                    id: body

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    anchors.leftMargin: 16
                    spacing: 12

                    Item {
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: 32
                        implicitHeight: 32

                        IconImage {
                            visible: toast.iconSource !== ""
                            anchors.fill: parent
                            source: toast.iconSource
                        }

                        Rectangle {
                            visible: toast.iconSource === ""
                            anchors.fill: parent
                            radius: 8
                            color: Theme.secondary

                            Icon {
                                anchors.centerIn: parent
                                name: toast.critical ? "bell" : "circle-check"
                                color: toast.critical ? Theme.destructive : Theme.success
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: toast.n.summary
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            IconButton {
                                implicitWidth: 20
                                implicitHeight: 20
                                icon: "x"
                                iconSize: 12
                                iconColor: Theme.muted
                                label: "알림 닫기"
                                onClicked: toast.n.dismiss()
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: toast.n.body
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }

                        Text {
                            visible: toast.n.appName !== ""
                            text: toast.n.appName
                            color: Theme.subtle
                            font.family: Theme.font
                            font.pixelSize: 11
                        }

                        RowLayout {
                            Layout.topMargin: 4
                            visible: actionRepeater.count > 0
                            spacing: 6

                            Repeater {
                                id: actionRepeater

                                model: {
                                    const out = [];
                                    const actions = toast.n.actions;
                                    for (let i = 0; i < actions.length && out.length < 3; i++) {
                                        if (actions[i].identifier !== "default")
                                            out.push(actions[i]);
                                    }
                                    return out;
                                }

                                Rectangle {
                                    id: actionButton

                                    required property var modelData
                                    required property int index

                                    implicitWidth: actionText.implicitWidth + 20
                                    implicitHeight: 26
                                    radius: Theme.radiusSm
                                    color: index === 0 ? Theme.primary
                                                       : actionMouse.containsMouse ? Theme.secondaryHover : Theme.secondary

                                    Accessible.role: Accessible.Button
                                    Accessible.name: modelData.text

                                    Text {
                                        id: actionText
                                        anchors.centerIn: parent
                                        text: actionButton.modelData.text
                                        color: actionButton.index === 0 ? Theme.primaryFg : Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: actionButton.modelData.invoke()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
