import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Volume indicator shown above the dock when the volume or mute state changes
// (hardware keys, other apps). Hidden while quick settings is open.
PanelWindow {
    id: root

    property bool shown: false
    property bool armed: false

    screen: ShellState.focusedScreen
    visible: shown
    anchors.bottom: true
    margins.bottom: 16
    implicitWidth: 260
    implicitHeight: 48
    // Stay clear of the dock and bar, but never push windows aside
    exclusiveZone: 0
    color: "transparent"
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "robinos-osd"

    // Ignore the initial values Pipewire reports at login
    Timer {
        running: true
        interval: 2000
        onTriggered: root.armed = true
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shown = false
    }

    function show() {
        if (!armed || ShellState.quickSettingsOpen)
            return;
        shown = true;
        hideTimer.restart();
    }

    Connections {
        target: ShellState

        function onVolumeChanged() {
            root.show();
        }

        function onMutedChanged() {
            root.show();
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Icon {
                name: ShellState.volumeIcon
                color: Theme.fg
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 3
                color: Theme.secondary

                Rectangle {
                    width: parent.width * (ShellState.muted ? 0 : Math.min(1, ShellState.volume))
                    height: parent.height
                    radius: 3
                    color: Theme.primary

                    Behavior on width {
                        NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic }
                    }
                }
            }

            Text {
                Layout.preferredWidth: 32
                horizontalAlignment: Text.AlignRight
                text: ShellState.muted ? "끔" : Math.round(ShellState.volume * 100) + ""
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Font.Medium
            }
        }
    }
}
