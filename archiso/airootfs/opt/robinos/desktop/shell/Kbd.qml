import QtQuick

// Keyboard key hint, e.g. "Super" or "↵".
Rectangle {
    id: root

    property string text

    implicitWidth: Math.max(label.implicitWidth + 12, 20)
    implicitHeight: 20
    radius: 5
    color: Theme.raised
    border.width: 1
    border.color: Theme.borderStrong

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: Theme.muted
        font.family: Theme.mono
        font.pixelSize: 11
    }
}
