import QtQuick
import QtQuick.Layouts

// Ghost button for the top bar; children are laid out in a vertically centered row.
Rectangle {
    id: root

    default property alias content: row.data
    property string label
    property bool active: false
    property int padding: 8
    property int spacing: 8

    signal clicked()
    // Wheel steps over the button, in eighths of a degree (120 per notch)
    signal wheeled(real delta)

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: 28
    radius: Theme.radiusSm
    color: active ? Theme.secondary : mouse.containsMouse ? Theme.hover : "transparent"

    Accessible.role: Accessible.Button
    Accessible.name: label

    Behavior on color {
        ColorAnimation { duration: Theme.durFast }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: wheel => root.wheeled(wheel.angleDelta.y)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: root.spacing
    }
}
