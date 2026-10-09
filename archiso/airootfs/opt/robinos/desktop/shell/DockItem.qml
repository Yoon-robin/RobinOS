import QtQuick
import Quickshell.Widgets

// One dock tile: a Lucide icon (pinned apps) or the app's theme icon (other running apps).
Rectangle {
    id: root

    property string icon
    property string appIcon
    property string label
    property bool running: false
    property bool focused: false
    property bool active: false
    property bool muted: false
    readonly property bool hovered: mouse.containsMouse

    signal clicked()
    // Pin to or unpin from the dock (Dock.qml)
    signal rightClicked()

    implicitWidth: 44
    implicitHeight: 44
    radius: 12
    color: focused || active ? Theme.secondary : hovered ? Theme.secondaryHover : Theme.raised
    border.width: 1
    border.color: focused || active ? Theme.borderStrong : Theme.border
    scale: mouse.pressed ? 0.94 : 1

    Accessible.role: Accessible.Button
    Accessible.name: running ? label + " (실행 중)" : label

    Behavior on color {
        ColorAnimation { duration: Theme.durFast }
    }

    Behavior on scale {
        NumberAnimation { duration: 90 }
    }

    Icon {
        visible: root.icon !== ""
        anchors.centerIn: parent
        name: root.icon
        size: 20
        color: root.muted ? Theme.muted : root.focused ? Theme.fg : Theme.fgSoft
    }

    IconImage {
        visible: root.icon === ""
        anchors.centerIn: parent
        implicitSize: 26
        source: root.appIcon
    }

    Rectangle {
        visible: root.running
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
        width: root.focused ? 10 : 4
        height: 4
        radius: 2
        color: root.focused ? Theme.fg : Theme.muted

        Behavior on width {
            NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
    }
}
