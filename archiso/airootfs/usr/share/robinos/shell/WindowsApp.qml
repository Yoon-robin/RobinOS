import QtQuick
import QtQuick.Layouts
import Quickshell
import "windowsapps.js" as WindowsApps

// Opened instead of an .exe or .msi (T-159): Windows programs don't run on Linux
// as they are, so say so, and when the file name is a program we know (카카오톡,
// Chrome, 한글 ...) offer what to use here: an app RobinOS has, one from the app
// store, or a web version. desktop/bin/robinos-windows-app hands the file over
// through `qs ipc ... call shell windowsApp <path>`.
FloatingWindow {
    id: root

    readonly property string path: ShellState.windowsAppPath
    readonly property string fileName: path.substring(path.lastIndexOf("/") + 1)
    readonly property var program: fileName !== "" ? WindowsApps.find(fileName) : null
    readonly property var choices: program ? program.choices : WindowsApps.fallback

    visible: ShellState.windowsAppOpen
    title: "윈도우 프로그램"
    implicitWidth: 560
    implicitHeight: content.implicitHeight + 48
    minimumSize: Qt.size(480, 320)
    color: Theme.bg

    onVisibleChanged: {
        if (!visible)
            ShellState.windowsAppOpen = false;
    }

    function choose(choice) {
        if (choice.app)
            Quickshell.execDetached(["gtk-launch", choice.app]);
        else if (choice.flathub)
            Quickshell.execDetached(["gnome-software", "--details=" + choice.flathub]);
        else if (choice.web)
            Quickshell.execDetached(["xdg-open", choice.web]);
        ShellState.windowsAppOpen = false;
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: ShellState.windowsAppOpen = false

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            RowLayout {
                spacing: 12

                Rectangle {
                    implicitWidth: 40
                    implicitHeight: 40
                    radius: Theme.radiusMd
                    color: Theme.secondary

                    Icon {
                        anchors.centerIn: parent
                        name: "info"
                        size: 20
                    }
                }

                ColumnLayout {
                    spacing: 2

                    Text {
                        text: root.program ? root.program.name + " 윈도우용 설치 파일이에요" : "윈도우 프로그램은 바로 실행되지 않아요"
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.maximumWidth: 440
                        text: root.fileName
                        color: Theme.muted
                        font.family: Theme.mono
                        font.pixelSize: 12
                        elide: Text.ElideMiddle
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: (root.program && root.program.note ? root.program.note + "\n\n" : "")
                      + ".exe와 .msi는 윈도우가 실행하는 형식이라 리눅스에서는 그대로 열리지 않아요. 대부분 같은 일을 하는 리눅스 앱이 있어요."
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 13
                lineHeight: 1.3
                wrapMode: Text.WordWrap
            }

            Text {
                text: root.program ? "대신 쓸 수 있는 것" : "그래도 실행해 보려면"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            Repeater {
                model: root.choices

                Rectangle {
                    id: choiceRow

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: 56
                    radius: Theme.radiusMd
                    color: choiceMouse.containsMouse || activeFocus ? Theme.hover : "transparent"
                    border.width: 1
                    border.color: Theme.border

                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.title

                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.choose(modelData)
                    Keys.onSpacePressed: root.choose(modelData)

                    FocusRing {
                        baseRadius: choiceRow.radius
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        Icon {
                            name: choiceRow.modelData.web ? "external" : choiceRow.modelData.flathub ? "download" : "sparkles"
                            size: 18
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: choiceRow.modelData.title
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 14
                                font.weight: Font.Medium
                            }

                            Text {
                                Layout.fillWidth: true
                                text: choiceRow.modelData.desc
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: choiceMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.choose(choiceRow.modelData)
                    }
                }
            }

            RowLayout {
                Layout.topMargin: 6

                Text {
                    Layout.fillWidth: true
                    text: "왜 그런지 궁금하면: 학습 센터의 리눅스 기초"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                }

                ActionButton {
                    variant: "outline"
                    text: "닫기"
                    onClicked: ShellState.windowsAppOpen = false
                }
            }
        }
    }
}
