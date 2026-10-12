import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "keys.js" as Keyboard

// RobinOS settings (T-149), laid out like macOS System Settings: the sections on
// the left, the chosen one on the right. Opened with Win+I, the launcher's "설정"
// (Windows name: 제어판) or `qs ipc ... call shell settings`. Sections that
// already have their own panel (sound, Wi-Fi, Bluetooth) open that panel.
FloatingWindow {
    id: root

    property string section: "appearance"
    // [label, value] rows for the about section, read by infoProc
    property var info: []

    readonly property var sections: [
        { key: "appearance", icon: "sun-moon", title: "개인 설정" },
        { key: "sound", icon: "volume", title: "소리", panel: true },
        { key: "wifi", icon: "wifi", title: "Wi-Fi", panel: true },
        { key: "bluetooth", icon: "bluetooth", title: "블루투스", panel: true },
        { key: "about", icon: "info", title: "정보" }
    ]
    readonly property var current: sections.find(s => s.key === section) ?? sections[0]

    visible: ShellState.settingsOpen
    title: "설정"
    implicitWidth: 860
    implicitHeight: Math.max(480, Math.min(600, ShellState.windowRoom))
    minimumSize: Qt.size(720, 480)
    color: Theme.bg

    onVisibleChanged: {
        if (!visible) {
            ShellState.settingsOpen = false;
            return;
        }
        if (ShellState.settingsSection !== "")
            pick(ShellState.settingsSection);
        infoProc.running = true;
    }

    function pick(key) {
        const s = sections.find(x => x.key === key);
        if (!s)
            return;
        if (s.panel) {
            // These have their own panel next to the bar
            ShellState.openDetail(s.key);
            return;
        }
        section = key;
    }

    function move(delta) {
        const pages = sections.filter(s => !s.panel);
        const i = pages.findIndex(s => s.key === section);
        section = pages[(i + delta + pages.length) % pages.length].key;
    }

    // One "label<TAB>value" line per fact; a missing tool leaves its line out
    Process {
        id: infoProc

        command: ["sh", "-c", [
            "v=$(robinctl version 2>/dev/null) && printf '버전\\t%s\\n' \"$v\"",
            "p=$(pacman -Q robinos 2>/dev/null) && printf 'RobinOS 패키지\\t%s\\n' \"${p#robinos }\"",
            "printf '커널\\t%s\\n' \"$(uname -r)\"",
            "m=$(cat /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name 2>/dev/null | tr '\\n' ' ') && [ -n \"${m// /}\" ] && printf '컴퓨터\\t%s\\n' \"$m\"",
            "printf 'CPU\\t%s\\n' \"$(sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -n 1)\"",
            "printf '메모리\\t%s\\n' \"$(awk '/^MemTotal/ { printf \"%.0f GB\", $2 / 1048576 }' /proc/meminfo)\"",
            "g=$(lspci 2>/dev/null | sed -n 's/^[^ ]* \\(VGA compatible controller\\|3D controller\\|Display controller\\): //p' | head -n 1) && [ -n \"$g\" ] && printf '그래픽\\t%s\\n' \"$g\"",
            "printf '디스크\\t%s\\n' \"$(df -h --output=size,avail / | awk 'NR == 2 { print $1 \" 중 \" $2 \" 남음\" }')\"",
            "printf '렌더링\\t%s\\n' \"$( [ \"$ROBINOS_RENDER\" = software ] && echo '소프트웨어 (그래픽 가속 없음)' || echo 'GPU 가속')\""
        ].join("; ")]
        stdout: StdioCollector {
            id: infoOut

            onStreamFinished: {
                const rows = [];
                for (const line of infoOut.text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab > 0)
                        rows.push([line.slice(0, tab), line.slice(tab + 1).trim()]);
                }
                root.info = rows;
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: ShellState.settingsOpen = false
        Keys.onUpPressed: root.move(-1)
        Keys.onDownPressed: root.move(1)

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ---- Sidebar ----
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 220
                color: Theme.raised

                Rectangle {
                    anchors.right: parent.right
                    width: 1
                    height: parent.height
                    color: Theme.border
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 2

                    RowLayout {
                        Layout.leftMargin: 6
                        Layout.topMargin: 8
                        Layout.bottomMargin: 14
                        spacing: 10

                        Mark {
                            size: 24
                        }

                        Text {
                            text: "설정"
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                    }

                    Repeater {
                        model: root.sections

                        Rectangle {
                            id: row

                            required property var modelData
                            readonly property bool selected: root.section === modelData.key

                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: Theme.radiusMd
                            color: selected ? Theme.secondary : rowMouse.containsMouse ? Theme.hover : "transparent"

                            Accessible.role: Accessible.PageTab
                            Accessible.name: modelData.title

                            activeFocusOnTab: true
                            Keys.onPressed: event => {
                                if (Keyboard.activates(event)) {
                                    root.pick(row.modelData.key);
                                    event.accepted = true;
                                }
                            }

                            FocusRing {
                                baseRadius: row.radius
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                Icon {
                                    name: row.modelData.icon
                                    size: 16
                                    color: row.selected ? Theme.fg : Theme.fgSoft
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.title
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    font.weight: row.selected ? Font.DemiBold : Font.Normal
                                }

                                // Opens its panel instead of a page here
                                Icon {
                                    visible: row.modelData.panel === true
                                    name: "external"
                                    size: 13
                                    color: Theme.subtle
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pick(row.modelData.key)
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            // ---- Page ----
            Flickable {
                id: flick

                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: page.implicitHeight + 64
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: page

                    x: 36
                    y: 32
                    width: flick.width - 72
                    spacing: 6

                    Text {
                        text: root.current.title
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.topMargin: 18
                        sourceComponent: root.section === "about" ? aboutPage : appearancePage
                    }
                }
            }
        }
    }

    // A labelled group of settings
    component Group: ColumnLayout {
        id: group

        property string title
        property string hint
        default property alias content: body.data

        Layout.fillWidth: true
        Layout.bottomMargin: 26
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: group.title
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Text {
                visible: text !== ""
                Layout.fillWidth: true
                text: group.hint
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 10
        }
    }

    Component {
        id: appearancePage

        ColumnLayout {
            spacing: 0

            Group {
                title: "모드"
                hint: "빠른 설정(Win+S)의 다크 모드와 같아요."

                Row {
                    spacing: 14

                    Repeater {
                        model: [{ dark: true, title: "다크" }, { dark: false, title: "라이트" }]

                        Column {
                            id: mode

                            required property var modelData
                            readonly property bool selected: Theme.dark === modelData.dark

                            spacing: 8

                            Rectangle {
                                width: 176
                                height: 112
                                radius: Theme.radius
                                color: mode.modelData.dark ? "#09090b" : "#ffffff"
                                border.width: mode.selected ? 2 : 1
                                border.color: mode.selected ? Theme.primary : Theme.border

                                Accessible.role: Accessible.RadioButton
                                Accessible.name: mode.modelData.title + " 모드"
                                Accessible.checked: mode.selected

                                activeFocusOnTab: true
                                Keys.onPressed: event => {
                                    if (Keyboard.activates(event)) {
                                        Theme.setDark(mode.modelData.dark);
                                        event.accepted = true;
                                    }
                                }

                                FocusRing {
                                    baseRadius: parent.radius
                                }

                                // A tiny desktop: the bar, a window, the dock
                                Rectangle {
                                    x: 8; y: 8
                                    width: parent.width - 16
                                    height: 8
                                    radius: 3
                                    color: mode.modelData.dark ? "#18181b" : "#f4f4f5"
                                }

                                Rectangle {
                                    x: 28; y: 26
                                    width: 96
                                    height: 58
                                    radius: 6
                                    color: mode.modelData.dark ? "#18181b" : "#f4f4f5"
                                    border.width: 1
                                    border.color: mode.modelData.dark ? "#27272a" : "#e4e4e7"

                                    Rectangle {
                                        x: 10; y: 12
                                        width: 44
                                        height: 6
                                        radius: 3
                                        color: Theme.accent
                                    }

                                    Rectangle {
                                        x: 10; y: 24
                                        width: 70
                                        height: 5
                                        radius: 2.5
                                        color: mode.modelData.dark ? "#3f3f46" : "#d4d4d8"
                                    }
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: parent.height - 16
                                    width: 54
                                    height: 9
                                    radius: 4
                                    color: mode.modelData.dark ? "#27272a" : "#e4e4e7"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Theme.setDark(mode.modelData.dark)
                                }
                            }

                            Text {
                                text: mode.modelData.title
                                color: mode.selected ? Theme.fg : Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: mode.selected ? Font.DemiBold : Font.Normal
                            }
                        }
                    }
                }
            }

            Group {
                title: "강조색"
                hint: "선택한 것, 진행 막대, 창 테두리의 색이에요. 지금: " + (Theme.accentLabels[Theme.accentName] ?? "")

                Row {
                    spacing: 12

                    Repeater {
                        model: Object.keys(Theme.accents)

                        Rectangle {
                            id: swatch

                            required property string modelData
                            readonly property bool selected: Theme.accentName === modelData

                            width: 32
                            height: 32
                            radius: 16
                            color: "transparent"
                            border.width: selected ? 2 : 0
                            border.color: Theme.accents[modelData]

                            Accessible.role: Accessible.RadioButton
                            Accessible.name: Theme.accentLabels[modelData]
                            Accessible.checked: selected

                            activeFocusOnTab: true
                            Keys.onPressed: event => {
                                if (Keyboard.activates(event)) {
                                    Theme.setAccent(swatch.modelData);
                                    event.accepted = true;
                                }
                            }

                            FocusRing {
                                baseRadius: swatch.radius
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                radius: 11
                                color: Theme.accents[swatch.modelData]
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Theme.setAccent(swatch.modelData)
                            }
                        }
                    }
                }
            }

            Group {
                title: "투명도"

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: Theme.radius
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "투명도 줄이기"
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }

                            Text {
                                Layout.fillWidth: true
                                text: Theme.lowPower ? "이 컴퓨터는 그래픽 가속이 없어서 이미 불투명하게 보여요."
                                                     : "바, 독, 패널을 불투명하게 해요. 뒤가 비치지 않아 글자가 더 또렷해요."
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }
                        }

                        Switch {
                            enabled: !Theme.lowPower
                            checked: Theme.reduceTransparency || Theme.lowPower
                            label: "투명도 줄이기"
                            onToggled: Theme.setReduceTransparency(!Theme.reduceTransparency)
                        }
                    }
                }
            }

            Group {
                title: "배경화면"
                hint: ShellState.wallpaperPath !== "" ? "사진을 배경으로 쓰고 있어요." : "RobinOS 기본 배경화면이에요."

                Row {
                    spacing: 8

                    ActionButton {
                        text: "사진으로 바꾸기"
                        variant: "outline"
                        onClicked: ShellState.chooseWallpaper()
                    }

                    ActionButton {
                        visible: ShellState.wallpaperPath !== ""
                        text: "기본 배경화면으로"
                        variant: "ghost"
                        onClicked: ShellState.resetWallpaper()
                    }
                }
            }
        }
    }

    Component {
        id: aboutPage

        ColumnLayout {
            spacing: 0

            RowLayout {
                Layout.bottomMargin: 24
                spacing: 16

                Mark {
                    size: 56
                }

                ColumnLayout {
                    spacing: 2

                    Text {
                        text: "RobinOS"
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 20
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "처음 쓰는 리눅스 · Arch Linux 기반"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 13
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: facts.implicitHeight
                radius: Theme.radius
                color: "transparent"
                border.width: 1
                border.color: Theme.border

                ColumnLayout {
                    id: facts

                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: root.info

                        Rectangle {
                            id: fact

                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: 40
                            color: "transparent"

                            Rectangle {
                                visible: fact.index > 0
                                width: parent.width
                                height: 1
                                color: Theme.border
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 16

                                Text {
                                    Layout.preferredWidth: 120
                                    text: fact.modelData[0]
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: fact.modelData[1]
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            ActionButton {
                Layout.topMargin: 16
                text: "자세히 진단하기 (robinctl doctor)"
                variant: "outline"
                onClicked: ShellState.runInTerminal("robinctl doctor")
            }
        }
    }
}
