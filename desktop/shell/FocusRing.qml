import QtQuick

// Keyboard focus outline (robin-ui: 2px of the blue ring, 2px outside), drawn around
// its parent while the parent has keyboard focus. Mouse clicks don't move focus, so
// it only shows up for Tab navigation.
Rectangle {
    // The parent's corner radius, so the ring follows its shape
    property real baseRadius: Theme.radiusMd

    anchors.fill: parent
    anchors.margins: -4
    radius: baseRadius + 4
    color: "transparent"
    border.width: 2
    border.color: Theme.ring
    visible: parent.activeFocus
}
