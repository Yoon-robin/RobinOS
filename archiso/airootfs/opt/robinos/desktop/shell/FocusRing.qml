import QtQuick

// Keyboard focus outline (shadcn's focus-visible ring), drawn just outside its
// parent while the parent has keyboard focus. Mouse clicks don't move focus, so
// it only shows up for Tab navigation.
Rectangle {
    // The parent's corner radius, so the ring follows its shape
    property real baseRadius: Theme.radiusMd

    anchors.fill: parent
    anchors.margins: -3
    radius: baseRadius + 3
    color: "transparent"
    border.width: 2
    border.color: Theme.ring
    visible: parent.activeFocus
}
