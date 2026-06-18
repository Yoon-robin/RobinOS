import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#10151C"

    Image {
        anchors.fill: parent
        source: "background.svg"
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#080C11"
        opacity: 0.28
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.86, 520)
        spacing: 22

        Image {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 128
            Layout.preferredHeight: 128
            source: "logo.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "RobinOS"
            color: "#EAF7FA"
            font.family: "Noto Sans"
            font.pixelSize: 52
            font.bold: true
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Security Learning Workstation"
            color: "#5EEBFF"
            font.family: "Noto Sans"
            font.pixelSize: 18
            font.bold: true
        }

        ComboBox {
            id: session
            Layout.fillWidth: true
            model: sessionModel
            textRole: "name"
            currentIndex: sessionModel.lastIndex
            background: Rectangle {
                color: "#18212C"
                border.color: "#2B3543"
                radius: 8
            }
            contentItem: Text {
                text: session.displayText
                color: "#EAF7FA"
                verticalAlignment: Text.AlignVCenter
                leftPadding: 14
            }
        }

        TextField {
            id: userName
            Layout.fillWidth: true
            placeholderText: "User"
            color: "#EAF7FA"
            text: userModel.lastUser
            selectByMouse: true
            background: Rectangle {
                color: "#18212C"
                border.color: userName.activeFocus ? "#5EEBFF" : "#2B3543"
                radius: 8
            }
            Keys.onReturnPressed: password.forceActiveFocus()
        }

        TextField {
            id: password
            Layout.fillWidth: true
            placeholderText: "Password"
            color: "#EAF7FA"
            echoMode: TextInput.Password
            selectByMouse: true
            background: Rectangle {
                color: "#18212C"
                border.color: password.activeFocus ? "#5EEBFF" : "#2B3543"
                radius: 8
            }
            Keys.onReturnPressed: sddm.login(userName.text, password.text, session.currentIndex)
        }

        Button {
            Layout.fillWidth: true
            text: "Log In"
            onClicked: sddm.login(userName.text, password.text, session.currentIndex)
            background: Rectangle {
                color: parent.down ? "#1BA6C9" : "#5EEBFF"
                radius: 8
            }
            contentItem: Text {
                text: parent.text
                color: "#10151C"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: 16
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Authorized labs, CTF practice, and legal security learning only."
            color: "#EAF7FA"
            opacity: 0.7
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 13
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 12

        Button {
            text: "Reboot"
            onClicked: sddm.reboot()
        }

        Button {
            text: "Power Off"
            onClicked: sddm.powerOff()
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}

