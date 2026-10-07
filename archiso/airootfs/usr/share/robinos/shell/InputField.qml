import QtQuick

// shadcn input: one line of text with a placeholder, a focus ring and an
// optional error state. Set password: true for hidden text.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder
    property bool password: false
    property bool invalid: false
    property alias inputFocus: input.activeFocus
    readonly property alias input: input

    signal accepted()

    implicitWidth: 240
    implicitHeight: 38
    radius: Theme.radiusMd
    color: "transparent"
    border.width: 1
    border.color: invalid ? Theme.destructive : input.activeFocus ? Theme.ring : Theme.input

    Behavior on border.color {
        ColorAnimation { duration: Theme.durFast }
    }

    TextInput {
        id: input

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.fg
        selectionColor: Theme.secondaryHover
        selectedTextColor: Theme.fg
        font.family: Theme.font
        font.pixelSize: 14
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        passwordCharacter: "•"
        clip: true
        activeFocusOnTab: true

        Accessible.role: Accessible.EditableText
        Accessible.name: root.placeholder

        onAccepted: root.accepted()

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: input.text === "" && input.preeditText === ""
            text: root.placeholder
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 14
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onPressed: mouse => {
            input.forceActiveFocus();
            mouse.accepted = false;
        }
    }
}
