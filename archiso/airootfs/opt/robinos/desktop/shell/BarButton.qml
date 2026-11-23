import QtQuick
import QtQuick.Layouts

// Bare button for the top bar; children are laid out in a vertically centered row.
// With a tone ("plain", "on", "note", "alarm") it is a robin-ui state chip instead:
// a pill on the indicator face with a short bar on the left that repeats the tone.
Rectangle {
    id: root

    default property alias content: row.data
    property string label
    property bool active: false
    property int padding: 8
    property int spacing: 8
    property string tone: ""
    readonly property bool chip: tone !== ""
    readonly property color toneColor: tone === "on" ? Theme.accent
                                     : tone === "note" ? Theme.note
                                     : tone === "alarm" ? Theme.destructiveSolid : Theme.plain

    signal clicked()
    // Wheel steps over the button, in eighths of a degree (120 per notch)
    signal wheeled(real delta)

    implicitWidth: row.implicitWidth + padding * 2 + (chip ? 6 : 0)
    implicitHeight: chip ? 24 : 28
    radius: chip ? height / 2 : Theme.radiusSm
    color: chip ? (mouse.containsMouse ? Theme.hover : Theme.panel)
         : active ? Theme.chosen : mouse.containsMouse ? Theme.hover : "transparent"
    border.width: chip ? 1 : 0
    border.color: Theme.panelBorder

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

    Rectangle {
        visible: root.chip
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: Math.round(parent.height * 0.44)
        radius: 1
        color: root.toneColor
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.chip ? 3 : 0
        spacing: root.spacing
    }
}
