import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "keys.js" as Keyboard

// Learning center: the missions of `robinctl learn` grouped like its list, with
// the progress, the next mission up front and the beginner CTF at the bottom.
// Missions are solved in a terminal: picking one opens `robinctl learn show N`
// there, and a mission `robinctl learn check` passes ticks off here right away.
// Opened from the launcher ("학습 미션"), the welcome wizard's Linux basics goal
// or `qs ipc ... call shell learnCenter`.
FloatingWindow {
    id: root

    // { number, group, groupStart, title, tools, done } from `robinctl learn tsv`
    property var missions: []
    property int ctfSolved: 0
    property int ctfCount: 5
    property bool loaded: false
    property bool failed: false

    readonly property int doneCount: missions.filter(m => m.done).length
    readonly property var nextMission: missions.find(m => !m.done) ?? null
    // [{ name, missions }]
    readonly property var groups: {
        const out = [];
        for (const m of missions) {
            if (m.groupStart || out.length === 0)
                out.push({ name: m.group, missions: [] });
            out[out.length - 1].missions.push(m);
        }
        return out;
    }

    visible: ShellState.learnCenterOpen
    title: "학습 센터"
    implicitWidth: 760
    implicitHeight: 660
    minimumSize: Qt.size(620, 520)
    color: Theme.bg

    onVisibleChanged: {
        if (!visible)
            ShellState.learnCenterOpen = false;
        else
            refresh();
    }

    function refresh() {
        if (!listProc.running)
            listProc.running = true;
    }

    function openMission(number) {
        ShellState.openTerminal("robinctl learn show " + number);
    }

    function openCtf() {
        ShellState.openTerminal("robinctl ctf");
    }

    Connections {
        target: ShellState

        function onLearnDoneChanged() {
            if (root.visible)
                root.refresh();
        }
    }

    // robinctl ctf writes the number of each solved challenge here
    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/robinos/ctf/solved"
        printErrors: false
        watchChanges: true
        onFileChanged: {
            if (root.visible)
                root.refresh();
        }
    }

    Process {
        id: listProc

        command: ["robinctl", "learn", "tsv"]
        stdout: StdioCollector {
            id: listOut

            onStreamFinished: {
                const missions = [];
                let group = "";
                for (const line of listOut.text.split("\n")) {
                    const f = line.split("\t");
                    if (f[0] === "mission" && f.length >= 6) {
                        // robinctl names the group on its first mission only
                        if (f[2] !== "")
                            group = f[2];
                        missions.push({ number: parseInt(f[1]), group: group, groupStart: f[2] !== "", title: f[3], tools: f[4], done: f[5] === "1" });
                    } else if (f[0] === "ctf" && f.length >= 3) {
                        root.ctfSolved = parseInt(f[1]);
                        root.ctfCount = parseInt(f[2]);
                    }
                }
                root.missions = missions;
                root.loaded = true;
            }
        }
        onExited: (exitCode, exitStatus) => root.failed = exitCode !== 0
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: ShellState.learnCenterOpen = false

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ---- Header ----
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 32
                Layout.rightMargin: 32
                Layout.topMargin: 28
                spacing: 12

                Mark {
                    size: 28
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "학습 센터"
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "미션은 터미널에서 직접 풀어요. 다 했으면 robinctl learn check로 확인해요."
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignBottom
                    visible: root.loaded
                    text: root.doneCount + " / " + root.missions.length + " 완료"
                    color: Theme.fgSoft
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
            }

            // Progress bar
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 32
                Layout.rightMargin: 32
                Layout.topMargin: 16
                implicitHeight: 6
                radius: 3
                color: Theme.secondary

                Rectangle {
                    width: root.missions.length > 0 ? parent.width * root.doneCount / root.missions.length : 0
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent

                    Behavior on width {
                        NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 32
                Layout.rightMargin: 32
                Layout.topMargin: 20
                visible: root.failed
                text: "미션 목록을 읽지 못했어요. 터미널에서 robinctl learn을 실행해 보세요."
                color: Theme.destructive
                font.family: Theme.font
                font.pixelSize: 14
                wrapMode: Text.WordWrap
            }

            // ---- Next mission ----
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 32
                Layout.rightMargin: 32
                Layout.topMargin: 20
                implicitHeight: nextRow.implicitHeight + 32
                visible: root.loaded
                radius: Theme.radius
                color: Theme.raised
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    id: nextRow

                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Rectangle {
                        implicitWidth: 40
                        implicitHeight: 40
                        radius: Theme.radiusMd
                        color: Theme.accent

                        Icon {
                            anchors.centerIn: parent
                            name: root.nextMission ? "graduation-cap" : "flag"
                            size: 20
                            color: "#ffffff"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: root.nextMission ? "다음 미션 · " + root.nextMission.group : "학습 미션을 모두 끝냈어요"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.nextMission ? root.nextMission.number + ". " + root.nextMission.title : "이제 입문 CTF에 도전해요"
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.nextMission ? root.nextMission.tools : "배운 기술을 섞어 플래그 5개를 찾아요"
                            color: Theme.muted
                            font.family: root.nextMission ? Theme.mono : Theme.font
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                    }

                    ActionButton {
                        text: root.nextMission ? "터미널에서 시작" : "CTF 열기"
                        onClicked: root.nextMission ? root.openMission(root.nextMission.number) : root.openCtf()
                    }
                }
            }

            // ---- All missions ----
            Flickable {
                id: flick

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 8
                contentHeight: list.implicitHeight + 16
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: list

                    x: 32
                    width: flick.width - 64
                    spacing: 0

                    Repeater {
                        model: root.groups

                        ColumnLayout {
                            id: group

                            required property var modelData

                            Layout.fillWidth: true
                            Layout.topMargin: 14
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 10
                                Layout.bottomMargin: 2
                                spacing: 8

                                Text {
                                    text: group.modelData.name
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: group.modelData.missions.filter(m => m.done).length + "/" + group.modelData.missions.length
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                }
                            }

                            Repeater {
                                model: group.modelData.missions

                                Rectangle {
                                    id: row

                                    required property var modelData
                                    readonly property bool isNext: root.nextMission !== null && root.nextMission.number === modelData.number

                                    Layout.fillWidth: true
                                    implicitHeight: 40
                                    radius: Theme.radiusMd
                                    color: mouse.containsMouse ? Theme.hover : "transparent"

                                    Accessible.role: Accessible.Button
                                    Accessible.name: "미션 " + modelData.number + ". " + modelData.title + (modelData.done ? ", 완료" : "")

                                    activeFocusOnTab: true
                                    Keys.onPressed: event => {
                                        if (Keyboard.activates(event)) {
                                            root.openMission(row.modelData.number);
                                            event.accepted = true;
                                        }
                                    }
                                    // Keep the focused row in view while tabbing through
                                    onActiveFocusChanged: {
                                        if (!activeFocus)
                                            return;
                                        const y = row.mapToItem(list, 0, 0).y;
                                        if (y < flick.contentY)
                                            flick.contentY = Math.max(0, y - 8);
                                        else if (y + height > flick.contentY + flick.height)
                                            flick.contentY = y + height - flick.height + 8;
                                    }

                                    FocusRing {
                                        baseRadius: row.radius
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 12

                                        Rectangle {
                                            implicitWidth: 20
                                            implicitHeight: 20
                                            radius: 10
                                            color: row.modelData.done ? Theme.success : "transparent"
                                            border.width: row.modelData.done ? 0 : row.isNext ? 2 : 1
                                            border.color: row.isNext ? Theme.accent : Theme.borderStrong

                                            Icon {
                                                anchors.centerIn: parent
                                                visible: row.modelData.done
                                                name: "check"
                                                size: 13
                                                stroke: 2.5
                                                color: Theme.bg
                                            }
                                        }

                                        Text {
                                            Layout.preferredWidth: 24
                                            text: row.modelData.number + "."
                                            color: Theme.muted
                                            font.family: Theme.mono
                                            font.pixelSize: 13
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: row.modelData.title
                                            color: row.modelData.done ? Theme.muted : Theme.fg
                                            font.family: Theme.font
                                            font.pixelSize: 14
                                            font.weight: row.isNext ? Font.Medium : Font.Normal
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.maximumWidth: 220
                                            text: row.modelData.tools
                                            color: Theme.muted
                                            font.family: Theme.mono
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }

                                        Icon {
                                            name: "chevron-right"
                                            size: 15
                                            color: Theme.subtle
                                        }
                                    }

                                    MouseArea {
                                        id: mouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.openMission(row.modelData.number)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- Beginner CTF ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.border
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 32
                Layout.rightMargin: 32
                Layout.topMargin: 14
                Layout.bottomMargin: 16
                spacing: 10

                Icon {
                    name: "flag"
                    size: 16
                    color: Theme.muted
                }

                Text {
                    text: "입문 CTF"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }

                Text {
                    Layout.fillWidth: true
                    text: root.ctfSolved + "/" + root.ctfCount + " 풀었어요 · 미션에서 배운 기술을 섞어 플래그를 찾아요"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                ActionButton {
                    text: "CTF 열기"
                    variant: "outline"
                    onClicked: root.openCtf()
                }
            }
        }
    }
}
