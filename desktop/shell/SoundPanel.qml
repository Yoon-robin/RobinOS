import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

// Where the sound goes and comes from, and each app's volume: the arrow next to
// Windows 11's volume slider plus its volume mixer. Opened from the arrow at the
// end of the quick settings volume row (ShellState.openDetail("sound")).
PanelWindow {
    id: root

    readonly property bool open: ShellState.detailPanel === "sound"
    property bool mapped: false
    property bool revealed: false

    readonly property var nodes: ShellState.toArray(Pipewire.nodes.values)
    // Hardware (and Bluetooth) devices; apps' own streams are left out
    readonly property var sinks: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => n.audio && !n.isSink && !n.isStream)
    // Apps playing into the current output, like Windows' volume mixer
    readonly property var apps: ShellState.toArray(appLinks.linkGroups).map(g => g.source)
        .filter(n => n && n.isStream)

    readonly property var mic: Pipewire.defaultAudioSource
    readonly property bool micReady: mic?.audio !== undefined && mic?.audio !== null

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
    WlrLayershell.namespace: "robinos-sound"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onOpenChanged: {
        if (open) {
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

    PwNodeLinkTracker {
        id: appLinks
        node: Pipewire.defaultAudioSink
    }

    // Volume and mute only come in for tracked nodes
    PwObjectTracker {
        objects: root.open ? root.apps.concat(root.mic ? [root.mic] : []) : []
    }

    function close() {
        ShellState.detailPanel = "";
    }

    function nodeName(n) {
        return n.description || n.nickname || n.name;
    }

    function appName(n) {
        const props = n.properties ?? {};
        return props["application.name"] || n.description || n.name;
    }

    function deviceIcon(n) {
        return /head(phone|set)|bluez/i.test(n.name + " " + n.description) ? "headphones" : "volume";
    }

    component SectionLabel: Text {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.topMargin: 4
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    component Hint: Text {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.bottomMargin: 4
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }

    // One output or input device; the chosen one is ticked
    component DeviceRow: Rectangle {
        id: row

        required property var node
        required property bool chosen
        property string icon: "volume"

        signal picked()

        Layout.fillWidth: true
        implicitHeight: 40
        radius: Theme.radiusMd
        color: rowMouse.containsMouse ? Theme.hover : chosen ? Theme.raised : "transparent"

        Accessible.role: Accessible.RadioButton
        Accessible.name: root.nodeName(node)
        Accessible.checked: chosen

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Icon {
                name: row.icon
                size: 16
                color: row.chosen ? Theme.fg : Theme.muted
            }

            Text {
                Layout.fillWidth: true
                text: root.nodeName(row.node)
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: row.chosen ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }

            Icon {
                visible: row.chosen
                name: "check"
                size: 14
                color: Theme.fg
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.picked()
        }
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
        width: 340
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
            spacing: 6

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.bottomMargin: 4
                text: "소리"
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            // ---- Output ----
            SectionLabel {
                text: "출력 장치"
            }

            Hint {
                visible: root.sinks.length === 0
                text: "소리 장치가 없어요. 스피커나 이어폰을 연결해 보세요."
            }

            Repeater {
                model: root.sinks

                DeviceRow {
                    required property var modelData

                    node: modelData
                    chosen: Pipewire.defaultAudioSink === modelData
                    icon: root.deviceIcon(modelData)
                    onPicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }

            // ---- Input ----
            SectionLabel {
                Layout.topMargin: 8
                text: "입력 장치 (마이크)"
            }

            Hint {
                visible: root.sources.length === 0
                text: "마이크가 없어요."
            }

            Repeater {
                model: root.sources

                DeviceRow {
                    required property var modelData

                    node: modelData
                    chosen: Pipewire.defaultAudioSource === modelData
                    icon: "mic"
                    onPicked: Pipewire.preferredDefaultAudioSource = modelData
                }
            }

            RowLayout {
                visible: root.micReady
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 6
                Layout.topMargin: 2
                spacing: 12

                IconButton {
                    implicitWidth: 20
                    implicitHeight: 20
                    icon: root.mic?.audio?.muted ? "mic-off" : "mic"
                    iconColor: Theme.muted
                    label: root.mic?.audio?.muted ? "마이크 켜기" : "마이크 끄기"
                    onClicked: root.mic.audio.muted = !root.mic.audio.muted
                }

                QsSlider {
                    Layout.fillWidth: true
                    label: "마이크 음량"
                    value: root.mic?.audio?.muted ? 0 : (root.mic?.audio?.volume ?? 0)
                    onMoved: value => {
                        root.mic.audio.muted = false;
                        root.mic.audio.volume = value;
                    }
                }
            }

            // ---- Volume mixer ----
            SectionLabel {
                Layout.topMargin: 8
                text: "앱별 음량"
            }

            Hint {
                visible: root.apps.length === 0
                text: "지금 소리를 내는 앱이 없어요."
            }

            Repeater {
                model: root.apps

                ColumnLayout {
                    id: appItem

                    required property var modelData
                    readonly property bool muted: modelData.audio?.muted ?? false

                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 6
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: root.appName(appItem.modelData)
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        IconButton {
                            implicitWidth: 20
                            implicitHeight: 20
                            icon: appItem.muted ? "volume-x" : "volume"
                            iconColor: Theme.muted
                            label: root.appName(appItem.modelData) + (appItem.muted ? " 음소거 해제" : " 음소거")
                            onClicked: appItem.modelData.audio.muted = !appItem.muted
                        }

                        QsSlider {
                            Layout.fillWidth: true
                            label: root.appName(appItem.modelData) + " 음량"
                            value: appItem.muted ? 0 : (appItem.modelData.audio?.volume ?? 0)
                            onMoved: value => {
                                appItem.modelData.audio.muted = false;
                                appItem.modelData.audio.volume = value;
                            }
                        }
                    }
                }
            }
        }
    }
}
