import QtQuick

// shadcn button: "default" (primary), "outline" or "ghost".
Rectangle {
    id: root

    property string text
    property string variant: "default"
    readonly property bool primary: variant === "default"

    signal clicked()

    implicitWidth: label.implicitWidth + 32
    implicitHeight: 36
    radius: Theme.radiusMd
    color: primary ? Theme.primary : mouse.containsMouse ? Theme.hover : "transparent"
    opacity: primary && mouse.containsMouse ? 0.9 : 1
    border.width: variant === "outline" ? 1 : 0
    border.color: Theme.border

    Accessible.role: Accessible.Button
    Accessible.name: text

    Behavior on color {
        ColorAnimation { duration: Theme.durFast }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.primary ? Theme.primaryFg : Theme.fg
        font.family: Theme.font
        font.pixelSize: 14
        font.weight: Font.Medium
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
