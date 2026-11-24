import QtQuick
import QtQuick.Layouts
import Quickshell
import "windowsapps.js" as WindowsApps

// Opened instead of an .exe or .msi (T-159): Windows programs don't run on Linux
// as they are, so say so, and when the file name is a program we know (카카오톡,
// Chrome, 한글 ...) offer what to use here: an app RobinOS has, one from the app
// store, or a web version. Where Wine is installed, running the file itself with
// it is one more choice, never done without asking (T-189).
// desktop/bin/robinos-windows-app hands the file over through
// `qs ipc ... call shell windowsApp <path>`.
FloatingWindow {
    id: root

    readonly property string path: ShellState.windowsAppPath
    readonly property string fileName: path.substring(path.lastIndexOf("/") + 1)
    readonly property var program: fileName !== "" ? WindowsApps.find(fileName) : null
    readonly property var choices: WindowsApps.choicesFor(program, ShellState.hasWine)
    readonly property bool offersWine: choices.some(choice => choice.wine === true)

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
        if (choice.wine)
            Quickshell.execDetached(["/usr/share/robinos/bin/robinos-wine", root.path]);
        else if (choice.app)
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
                        text: root.program ? root.program.name + " 윈도우용 설치 파일이에요"
                              : root.offersWine ? "윈도우 프로그램이에요" : "윈도우 프로그램은 바로 실행되지 않아요"
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 17
                        font.weight: Theme.weightHead
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
                      + (root.offersWine
                         ? ".exe와 .msi는 윈도우가 실행하는 형식이에요. Wine으로 실행해 볼 수 있지만, 같은 일을 하는 리눅스 앱이 있으면 그쪽이 더 잘 돼요. Wine 안의 프로그램은 윈도우에서처럼 내 파일을 읽고 고칠 수 있으니, 믿을 수 있는 곳에서 받은 파일만 실행해요."
                         : ".exe와 .msi는 윈도우가 실행하는 형식이라 리눅스에서는 그대로 열리지 않아요. 대부분 같은 일을 하는 리눅스 앱이 있어요.")
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 13
                lineHeight: 1.3
                wrapMode: Text.WordWrap
            }

            Text {
                text: root.program ? (root.offersWine ? "할 수 있는 것" : "대신 쓸 수 있는 것")
                      : root.offersWine ? "실행해 보려면" : "그래도 실행해 보려면"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Theme.weightStrong
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
                            name: choiceRow.modelData.wine ? "app" : choiceRow.modelData.web ? "external"
                                  : choiceRow.modelData.flathub ? "download" : "sparkles"
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
                                font.weight: Theme.weightStrong
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

                // Mission 16 (리버싱 기초) compares a Linux program with a Windows
                // one, byte by byte (T-184)
                ActionButton {
                    // The words line up with the text above
                    Layout.leftMargin: -14
                    variant: "ghost"
                    text: "왜 안 열리는지 알아보기"
                    onClicked: {
                        ShellState.windowsAppOpen = false;
                        ShellState.openTerminal("robinctl learn show 16");
                    }
                }

                Item {
                    Layout.fillWidth: true
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
