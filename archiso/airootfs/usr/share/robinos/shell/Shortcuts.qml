import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Every keyboard shortcut on one card (Super+F1, the launcher's "단축키 보기"),
// with the terminal basics people from Windows trip over: copying is
// Ctrl+Shift+C there, Ctrl+C stops a command. Escape or a click outside closes it.
// Keep it in step with robinos.lua and docs/desktop.md's 단축키 table.
PanelWindow {
    id: root

    readonly property bool open: ShellState.shortcutsOpen
    property bool mapped: false
    property bool revealed: false

    readonly property var groups: [
        { title: "창", items: [
            { keys: ["Alt", "Tab"], title: "다음 창 (Shift를 같이 누르면 이전 창)" },
            { keys: ["Alt", "F4"], title: "창 닫기 (Win+Q도 돼요)" },
            { keys: ["Win", "D"], title: "바탕 화면 보기, 다시 누르면 되돌리기" },
            { keys: ["Win", "↑"], title: "최대화 (Win+M도 돼요)" },
            { keys: ["Win", "F"], title: "전체 화면" },
            { keys: ["Win", "T"], title: "자유 배치와 타일 배치 바꾸기" },
            { keys: ["Win", "1~9"], title: "작업 공간 바꾸기 (Shift: 창 옮기기)" },
            { keys: ["Win", "←", "→"], title: "창을 화면 왼쪽·오른쪽 절반에" },
            { keys: ["Win", "↓"], title: "원래 크기로, 다시 누르면 최소화" },
            { keys: ["Win", "Ctrl", "←", "→"], title: "이전·다음 작업 공간" }
        ] },
        { title: "앱과 시스템", items: [
            { keys: ["Win", "Space"], title: "런처: 앱과 명령 찾기" },
            { keys: ["Win", "Enter"], title: "터미널" },
            { keys: ["Win", "E"], title: "파일" },
            { keys: ["Win", "B"], title: "브라우저" },
            { keys: ["Win", "S"], title: "빠른 설정 (Win+I도 돼요)" },
            { keys: ["Win", "V"], title: "클립보드 기록" },
            { keys: ["Win", "Shift", "S"], title: "화면 일부 캡처 (전체는 Print)" },
            { keys: ["Ctrl", "Shift", "Esc"], title: "작업 관리자" },
            { keys: ["Win", "Alt", "D"], title: "달력" },
            { keys: ["Win", "N"], title: "알림 센터 (지난 알림, 방해 금지)" },
            { keys: ["Win", "L"], title: "화면 잠금" },
            { keys: ["오른쪽 Alt"], title: "한/영 전환" }
        ] },
        { title: "터미널", items: [
            { keys: ["Ctrl", "Shift", "C"], title: "복사 (Ctrl+C가 아니에요)" },
            { keys: ["Ctrl", "Shift", "V"], title: "붙여 넣기" },
            { keys: ["Ctrl", "C"], title: "실행 중인 명령 멈추기" },
            { keys: ["Tab"], title: "명령과 파일 이름 자동 완성" },
            { keys: ["↑", "↓"], title: "전에 친 명령 다시 부르기" },
            { keys: ["Ctrl", "R"], title: "전에 친 명령 검색" },
            { keys: ["Ctrl", "L"], title: "화면 지우기 (clear)" },
            { keys: ["Ctrl", "D"], title: "터미널 닫기 (exit)" }
        ] }
    ]

    screen: ShellState.overlayScreen ?? Quickshell.screens[0]
    visible: mapped
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "robinos-shortcuts"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onOpenChanged: {
        if (open) {
            mapped = true;
            Qt.callLater(() => {
                root.revealed = true;
                card.forceActiveFocus();
            });
        } else {
            revealed = false;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: Theme.dur
        onTriggered: {
            if (!root.open)
                root.mapped = false;
        }
    }

    function close() {
        ShellState.shortcutsOpen = false;
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.revealed ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.dur }
        }
    }

    // Click anywhere outside the card to close
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 1120)
        height: content.implicitHeight + 56
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        opacity: root.revealed ? 1 : 0
        scale: root.revealed ? 1 : 0.98
        focus: true

        Behavior on opacity {
            NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic }
        }

        layer.enabled: !Theme.lowPower
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            shadowVerticalOffset: 12
        }

        Keys.onEscapePressed: root.close()

        // Keep clicks inside the card from closing it
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 28
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "단축키"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: "Win 키는 리눅스에서 Super 키라고 불러요. 이 안내는 Win+F1로 언제든 다시 열어요."
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                Kbd {
                    text: "Esc"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 28

                Repeater {
                    model: root.groups

                    ColumnLayout {
                        id: group

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 9

                        Text {
                            Layout.bottomMargin: 2
                            text: group.modelData.title
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Repeater {
                            model: group.modelData.items

                            RowLayout {
                                id: shortcut

                                required property var modelData

                                Layout.fillWidth: true
                                spacing: 4

                                Repeater {
                                    model: shortcut.modelData.keys

                                    Kbd {
                                        required property string modelData
                                        text: modelData
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 6
                                    text: shortcut.modelData.title
                                    color: Theme.fgSoft
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
