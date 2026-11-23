import QtQuick

// robin-ui input (rk-input): the control face in its 1px line, 7px corners; the line
// turns blue with focus and red when invalid. The placeholder says what to type.
// Set password: true for hidden text.
Rectangle {
    id: root

    property alias text: textInput.text
    property string placeholder
    property bool password: false
    property bool invalid: false
    property alias inputFocus: textInput.activeFocus
    readonly property alias input: textInput

    signal accepted()

    implicitWidth: 240
    implicitHeight: 36
    radius: Theme.radiusMd
    color: Theme.secondary
    border.width: 1
    border.color: invalid ? Theme.destructiveSolid : textInput.activeFocus ? Theme.ring : Theme.input

    Behavior on border.color {
        ColorAnimation { duration: Theme.durFast }
    }

    TextInput {
        id: textInput

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.head
        selectionColor: Theme.accentSoft
        selectedTextColor: Theme.head
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
            visible: textInput.text === "" && textInput.preeditText === ""
            text: root.placeholder
            color: Theme.subtle
            font.family: Theme.font
            font.pixelSize: 14
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onPressed: mouse => {
            textInput.forceActiveFocus();
            mouse.accepted = false;
        }
    }
}
