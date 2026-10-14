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
    // What `robinctl update --status` said (state, count, bytes, kernel, metered,
    // next_snapshot, flatpak, robinos); null before the first answer
    property var updateInfo: null
    // `timedatectl show`: Timezone, NTP (yes/no), NTPSynchronized, LocalRTC, plus Now
    property var time: ({})
    // `robinos-default-apps list`: one entry per kind (key, label, current, currentName, apps)
    property var defaultApps: []
    // The kind whose list of apps is open
    property string openKind: ""
    property bool updateChecking: false
    readonly property var upd: updateInfo ?? ({})
    readonly property int updateAll: (upd.count ?? 0) + (upd.flatpak ?? 0)
    readonly property string updateTitle: ShellState.isLive ? "라이브에서는 업데이트하지 않아요"
                                         : updateChecking ? "확인하는 중이에요…"
                                         : upd.state === "unknown" ? "업데이트를 확인하지 못했어요"
                                         : updateAll > 0 ? "업데이트 " + updateAll + "개가 있어요"
                                         : upd.state ? "모두 최신이에요" : ""
    readonly property string updateDetail: {
        if (ShellState.isLive)
            return "RobinOS를 컴퓨터에 설치한 뒤에 업데이트해요.";
        if (updateChecking)
            return "";
        if (upd.state === "unknown")
            return "인터넷에 연결돼 있는지 확인해 주세요. 그래도 안 되면 잠시 뒤에 다시 확인해요.";
        const parts = [];
        if ((upd.count ?? 0) > 0)
            parts.push("시스템 패키지 " + upd.count + "개" + (upd.bytes > 0 ? ", 받을 크기 " + sizeText(upd.bytes) : ""));
        if ((upd.flatpak ?? 0) > 0)
            parts.push("앱 스토어 앱 " + upd.flatpak + "개");
        if (upd.kernel)
            parts.push("커널이 바뀌어요. 끝나면 컴퓨터를 다시 시작해요");
        return parts.join(" · ");
    }

    readonly property var sections: [
        { key: "appearance", icon: "sun-moon", title: "개인 설정" },
        { key: "update", icon: "download", title: "업데이트" },
        { key: "datetime", icon: "globe", title: "날짜와 시간" },
        { key: "pointer", icon: "mouse-pointer", title: "마우스와 터치패드" },
        { key: "keyboard", icon: "keyboard", title: "키보드" },
        { key: "apps", icon: "app", title: "기본 앱" },
        { key: "power", icon: "battery", title: "전원" },
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
        if (section === "update")
            checkUpdates();
        if (section === "datetime")
            readTime();
        if (section === "apps")
            readApps();
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

    function sizeText(bytes) {
        return bytes >= 1073741824 ? (bytes / 1073741824).toFixed(1) + "GB" : Math.max(1, Math.round(bytes / 1048576)) + "MB";
    }

    function checkUpdates() {
        if (ShellState.isLive || updateProc.running)
            return;
        updateInfo = null;
        updateChecking = true;
        updateProc.running = true;
    }

    function readTime() {
        if (!timeProc.running)
            timeProc.running = true;
    }

    function readApps() {
        if (!appsProc.running)
            appsProc.running = true;
    }

    function setDefaultApp(kind, id) {
        setAppProc.command = ["/usr/share/robinos/bin/robinos-default-apps", "set", kind, id];
        setAppProc.running = true;
        openKind = "";
    }

    onSectionChanged: {
        if (section === "update" && visible && updateInfo === null)
            checkUpdates();
        if (section === "datetime" && visible)
            readTime();
        if (section === "apps" && visible)
            readApps();
        openKind = "";
    }

    // The terminal that changes a setting is a window of its own: look again now and then
    Timer {
        interval: 4000
        repeat: true
        running: root.visible && root.section === "datetime"
        onTriggered: root.readTime()
    }

    function move(delta) {
        const pages = sections.filter(s => !s.panel);
        const i = pages.findIndex(s => s.key === section);
        section = pages[(i + delta + pages.length) % pages.length].key;
    }

    // The time zone, whether the clock follows the internet, and the clock itself
    Process {
        id: timeProc

        command: ["sh", "-c", "timedatectl show -p Timezone -p NTP -p NTPSynchronized -p LocalRTC 2>/dev/null; date '+Now=%Y-%m-%d %H:%M'"]
        stdout: StdioCollector {
            id: timeOut

            onStreamFinished: {
                const found = {};
                for (const line of timeOut.text.split("\n")) {
                    const eq = line.indexOf("=");
                    if (eq > 0)
                        found[line.slice(0, eq)] = line.slice(eq + 1).trim();
                }
                root.time = found;
            }
        }
    }

    // Which app opens what, and which installed apps could
    Process {
        id: appsProc

        command: ["/usr/share/robinos/bin/robinos-default-apps", "list"]
        stdout: StdioCollector {
            id: appsOut

            onStreamFinished: {
                try {
                    root.defaultApps = JSON.parse(appsOut.text.trim());
                } catch (error) {
                    root.defaultApps = [];
                }
            }
        }
    }

    Process {
        id: setAppProc

        onExited: (exitCode, exitStatus) => root.readApps()
    }

    // What an update would bring; robinctl looks in its own copy of the package databases
    Process {
        id: updateProc

        command: ["robinctl", "update", "--status"]
        stdout: StdioCollector {
            id: updateOut

            onStreamFinished: {
                root.updateChecking = false;
                try {
                    const lines = updateOut.text.trim().split("\n");
                    root.updateInfo = JSON.parse(lines[lines.length - 1]);
                } catch (error) {
                    root.updateInfo = { state: "unknown" };
                }
            }
        }
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
                        sourceComponent: root.section === "about" ? aboutPage
                                         : root.section === "update" ? updatePage
                                         : root.section === "datetime" ? dateTimePage
                                         : root.section === "pointer" ? pointerPage
                                         : root.section === "keyboard" ? keyboardPage
                                         : root.section === "apps" ? appsPage
                                         : root.section === "power" ? powerPage : appearancePage
                    }
                }
            }
        }
    }

    // Over the whole window; choosing a zone runs the command in a terminal, so the
    // person sees (and can learn) what changes the time zone
    ZonePicker {
        id: zonePicker

        anchors.fill: parent
        current: root.time.Timezone ?? ""
        onPicked: zone => ShellState.runInTerminal("sudo timedatectl set-timezone '" + zone + "' && timedatectl | head -n 6")
        onClosed: root.readTime()
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

    // One setting with a switch: a title, a line under it, and the switch on the right
    component SwitchRow: Rectangle {
        id: switchRow

        property string title
        property string desc
        property bool checked
        signal toggled

        Layout.fillWidth: true
        implicitHeight: Math.max(64, rowText.implicitHeight + 24)
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
                id: rowText

                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: switchRow.title
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                Text {
                    Layout.fillWidth: true
                    text: switchRow.desc
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }

            Switch {
                checked: switchRow.checked
                label: switchRow.title
                onToggled: switchRow.toggled()
            }
        }
    }

    // A setting on a scale: a title, the value in words, a line under it and a slider
    component SliderRow: Rectangle {
        id: sliderRow

        property string title
        property string desc
        property string valueText
        property string lowLabel
        property string highLabel
        // 0..1
        property real value
        signal moved(real value)

        Layout.fillWidth: true
        implicitHeight: sliderColumn.implicitHeight + 28
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            id: sliderColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: sliderRow.title
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                Text {
                    text: sliderRow.valueText
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                }
            }

            Text {
                visible: text !== ""
                Layout.fillWidth: true
                text: sliderRow.desc
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            QsSlider {
                Layout.fillWidth: true
                Layout.topMargin: 4
                label: sliderRow.title
                value: sliderRow.value
                onMoved: v => sliderRow.moved(v)
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: sliderRow.lowLabel
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 11
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: sliderRow.highLabel
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 11
                }
            }
        }
    }

    // One setting with a few values to pick from, as buttons in a row: a title, a line
    // under it and the options ([{ value, label }]); the one equal to current is on
    component ChoiceRow: Rectangle {
        id: choiceRow

        property string title
        property string desc
        property var options: []
        property var current
        signal picked(var value)

        Layout.fillWidth: true
        implicitHeight: choiceColumn.implicitHeight + 28
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            id: choiceColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 6

            Text {
                text: choiceRow.title
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            Text {
                visible: text !== ""
                Layout.fillWidth: true
                text: choiceRow.desc
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8

                Repeater {
                    model: choiceRow.options

                    Rectangle {
                        id: choice

                        required property var modelData
                        readonly property bool selected: choiceRow.current === modelData.value

                        width: choiceLabel.implicitWidth + 24
                        height: 32
                        radius: Theme.radiusMd
                        color: selected ? Theme.primary : choiceMouse.containsMouse ? Theme.hover : "transparent"
                        border.width: selected ? 0 : 1
                        border.color: Theme.border

                        Accessible.role: Accessible.RadioButton
                        Accessible.name: choiceRow.title + ": " + modelData.label
                        Accessible.checked: selected

                        activeFocusOnTab: true
                        Keys.onPressed: event => {
                            if (Keyboard.activates(event)) {
                                choiceRow.picked(choice.modelData.value);
                                event.accepted = true;
                            }
                        }

                        FocusRing {
                            baseRadius: choice.radius
                        }

                        Text {
                            id: choiceLabel

                            anchors.centerIn: parent
                            text: choice.modelData.label
                            color: choice.selected ? Theme.primaryFg : Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.weight: choice.selected ? Font.DemiBold : Font.Normal
                        }

                        MouseArea {
                            id: choiceMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: choiceRow.picked(choice.modelData.value)
                        }
                    }
                }
            }
        }
    }

    // One choice of several, like a radio button: Enter or Space picks it
    component RadioRow: Rectangle {
        id: radioRow

        property string title
        property string desc
        property bool selected
        signal picked

        Layout.fillWidth: true
        implicitHeight: 52
        radius: Theme.radius
        color: radioMouse.containsMouse ? Theme.hover : "transparent"
        border.width: 1
        border.color: selected ? Theme.fg : Theme.border

        Accessible.role: Accessible.RadioButton
        Accessible.name: title
        Accessible.checked: selected

        activeFocusOnTab: true
        Keys.onPressed: event => {
            if (Keyboard.activates(event)) {
                radioRow.picked();
                event.accepted = true;
            }
        }

        FocusRing {
            baseRadius: radioRow.radius
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12

            Rectangle {
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: "transparent"
                border.width: 1
                border.color: radioRow.selected ? Theme.fg : Theme.borderStrong

                Rectangle {
                    anchors.centerIn: parent
                    visible: radioRow.selected
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.fg
                }
            }

            Text {
                text: radioRow.title
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            Text {
                Layout.fillWidth: true
                text: radioRow.desc
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: radioMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: radioRow.picked()
        }
    }

    // 마우스와 터치패드: Hyprland's input options through ShellState.setInput
    Component {
        id: pointerPage

        ColumnLayout {
            readonly property var prefs: ShellState.inputPrefs

            spacing: 0

            Group {
                title: "터치패드"
                hint: "노트북의 터치패드에만 적용돼요."

                SwitchRow {
                    title: "탭해서 클릭"
                    desc: "터치패드를 톡 치면 클릭이에요. 꺼도 터치패드를 눌러서 클릭할 수 있어요."
                    checked: prefs.tap
                    onToggled: ShellState.setInput("tap", !prefs.tap)
                }

                SwitchRow {
                    title: "스크롤 방향: 손가락을 따라가기"
                    desc: prefs.natural ? "손가락을 위로 밀면 화면이 위로 올라가요(휴대폰과 맥처럼). 끄면 윈도우처럼 손가락을 위로 밀 때 화면이 아래로 내려가요."
                                        : "손가락을 위로 밀면 화면이 아래로 내려가요(윈도우처럼). 켜면 휴대폰처럼 손가락을 따라 올라가요."
                    checked: prefs.natural
                    onToggled: ShellState.setInput("natural", !prefs.natural)
                }

                SwitchRow {
                    title: "글을 쓰는 동안 터치패드 끄기"
                    desc: "타자를 치다 손바닥이 닿아서 커서가 튀는 일을 막아요."
                    checked: prefs.typing_off
                    onToggled: ShellState.setInput("typing_off", !prefs.typing_off)
                }
            }

            Group {
                title: "마우스"
                hint: "바퀴가 달린 마우스에 적용돼요."

                SwitchRow {
                    title: "휠 방향 뒤집기"
                    desc: prefs.wheel_flip ? "휠을 위로 굴리면 화면이 아래로 내려가요(맥처럼)."
                                           : "휠을 위로 굴리면 화면이 위로 올라가요(윈도우처럼)."
                    checked: prefs.wheel_flip
                    onToggled: ShellState.setInput("wheel_flip", !prefs.wheel_flip)
                }
            }

            Group {
                title: "포인터 속도"
                hint: "마우스와 터치패드 모두 같아요."

                SliderRow {
                    title: "커서가 움직이는 빠르기"
                    valueText: prefs.speed === 0 ? "기본" : (prefs.speed < 0 ? "느리게 " : "빠르게 ") + Math.round(Math.abs(prefs.speed) * 100) + "%"
                    lowLabel: "느리게"
                    highLabel: "빠르게"
                    value: (prefs.speed + 1) / 2
                    onMoved: v => ShellState.setInput("speed", Math.round((v * 2 - 1) * 20) / 20)
                }
            }

            ActionButton {
                Layout.alignment: Qt.AlignLeft
                variant: "outline"
                text: "기본값으로 되돌리기"
                onClicked: ShellState.resetInput(["tap", "natural", "typing_off", "wheel_flip", "speed"])
            }
        }
    }

    // 키보드: the key repeat rate, and the 한/영 shortcut (the same choice as the welcome wizard)
    Component {
        id: keyboardPage

        ColumnLayout {
            readonly property var prefs: ShellState.inputPrefs

            spacing: 0

            Group {
                title: "한/영 전환"
                hint: "한/영 키와 오른쪽 Alt는 언제나 돼요. 하나 더 고를 수 있어요."

                RadioRow {
                    title: "Ctrl + Space"
                    desc: "기본값이에요"
                    selected: ShellState.imeShortcut === "ctrl"
                    onPicked: ShellState.setImeShortcut("ctrl")
                }

                RadioRow {
                    title: "Shift + Space"
                    desc: "윈도우 한국어 입력기에서 쓰던 방식이에요"
                    selected: ShellState.imeShortcut === "shift"
                    onPicked: ShellState.setImeShortcut("shift")
                }

                RadioRow {
                    title: "추가 단축키 없음"
                    desc: "한/영 키와 오른쪽 Alt만 써요"
                    selected: ShellState.imeShortcut === "none"
                    onPicked: ShellState.setImeShortcut("none")
                }
            }

            Group {
                title: "키를 꾹 누르면"
                hint: "아래 칸에서 키를 꾹 눌러 보면서 맞춰 보세요."

                InputField {
                    Layout.fillWidth: true
                    placeholder: "여기에 눌러 보세요"
                }

                SliderRow {
                    title: "글자가 반복되는 빠르기"
                    valueText: "1초에 " + prefs.repeat_rate + "번"
                    lowLabel: "느리게"
                    highLabel: "빠르게"
                    value: (prefs.repeat_rate - 10) / 50
                    onMoved: v => ShellState.setInput("repeat_rate", Math.round(10 + v * 50))
                }

                SliderRow {
                    title: "반복이 시작되기까지"
                    valueText: (prefs.repeat_delay / 1000).toFixed(2).replace(/0$/, "") + "초"
                    lowLabel: "짧게"
                    highLabel: "길게"
                    value: (prefs.repeat_delay - 200) / 800
                    onMoved: v => ShellState.setInput("repeat_delay", Math.round((200 + v * 800) / 50) * 50)
                }
            }

            ActionButton {
                Layout.alignment: Qt.AlignLeft
                variant: "outline"
                text: "기본값으로 되돌리기"
                onClicked: {
                    ShellState.resetInput(["repeat_rate", "repeat_delay"]);
                    ShellState.setImeShortcut("ctrl");
                }
            }
        }
    }

    // 전원: how long of doing nothing locks the screen, turns it off and puts a laptop to
    // sleep (ShellState.setPower; robinos-idle-config turns them into hypridle's policy)
    Component {
        id: powerPage

        ColumnLayout {
            id: powerBody

            readonly property var prefs: ShellState.powerPrefs
            readonly property var never: ({ value: 0, label: "안 함" })

            spacing: 0

            Group {
                title: "화면"
                hint: "마우스와 키보드를 쓰지 않을 때예요. 잠그기 1분 전에 화면이 어두워져요."

                ChoiceRow {
                    title: "화면 잠그기"
                    desc: "다시 쓰려면 비밀번호를 입력해요."
                    options: [{ value: 1, label: "1분" }, { value: 3, label: "3분" }, { value: 5, label: "5분" },
                              { value: 10, label: "10분" }, { value: 15, label: "15분" }, { value: 30, label: "30분" }, powerBody.never]
                    current: powerBody.prefs.lock
                    onPicked: value => ShellState.setPower("lock", value)
                }

                ChoiceRow {
                    title: "화면 끄기"
                    desc: "화면이 꺼져도 컴퓨터는 켜져 있어요. 아무 키나 누르면 돌아와요."
                    options: [{ value: 2, label: "2분" }, { value: 5, label: "5분" }, { value: 10, label: "10분" },
                              { value: 15, label: "15분" }, { value: 30, label: "30분" }, powerBody.never]
                    current: powerBody.prefs.screen_off
                    onPicked: value => ShellState.setPower("screen_off", value)
                }
            }

            Group {
                title: "잠자기"
                hint: ShellState.hasBattery ? "충전기를 꽂아 두면 잠들지 않아요(윈도우처럼). 덮개를 닫으면 언제나 잠들어요."
                                            : "배터리가 없는 컴퓨터는 저절로 잠들지 않아요. 빠른 설정(Win+S)의 전원 메뉴에서 \"잠자기\"로 직접 재워요."

                ChoiceRow {
                    visible: ShellState.hasBattery
                    title: "배터리로 쓸 때 잠자기"
                    desc: ""
                    options: [{ value: 5, label: "5분" }, { value: 10, label: "10분" }, { value: 15, label: "15분" },
                              { value: 30, label: "30분" }, { value: 60, label: "1시간" }, powerBody.never]
                    current: powerBody.prefs.suspend
                    onPicked: value => ShellState.setPower("suspend", value)
                }
            }

            ActionButton {
                Layout.alignment: Qt.AlignLeft
                variant: "outline"
                text: "기본값으로 되돌리기"
                onClicked: ShellState.resetPower()
            }
        }
    }

    // 기본 앱: robinos-default-apps lists the apps that can open each kind and sets the choice
    Component {
        id: appsPage

        ColumnLayout {
            spacing: 0

            Group {
                title: "파일을 열 때 쓰는 앱"
                hint: "고른 앱은 ~/.config/mimeapps.list에 저장돼요. 터미널에서는 xdg-mime default 앱.desktop 형식으로 같은 일을 해요."

                Text {
                    visible: root.defaultApps.length === 0
                    text: "읽는 중이에요…"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 13
                }

                Repeater {
                    model: root.defaultApps

                    ColumnLayout {
                        id: kindRow

                        required property var modelData
                        readonly property bool open: root.openKind === modelData.key

                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 60
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
                                        text: kindRow.modelData.label
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: kindRow.modelData.apps.length === 0 ? "설치된 앱이 없어요"
                                              : kindRow.modelData.currentName !== "" ? kindRow.modelData.currentName
                                              : kindRow.modelData.current !== "" ? kindRow.modelData.current : "정해지지 않았어요"
                                        color: Theme.muted
                                        font.family: Theme.font
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }

                                ActionButton {
                                    visible: kindRow.modelData.apps.length > 0
                                    variant: "outline"
                                    text: kindRow.open ? "닫기" : "바꾸기"
                                    onClicked: root.openKind = kindRow.open ? "" : kindRow.modelData.key
                                }
                            }
                        }

                        Repeater {
                            model: kindRow.open ? kindRow.modelData.apps : []

                            RadioRow {
                                required property var modelData

                                Layout.leftMargin: 20
                                title: modelData.name
                                desc: modelData.id
                                selected: kindRow.modelData.current === modelData.id
                                onPicked: root.setDefaultApp(kindRow.modelData.key, modelData.id)
                            }
                        }
                    }
                }
            }
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

            // T-161, like Windows' 접근성 and macOS' 손쉬운 사용
            Group {
                title: "손쉬운 사용"
                hint: "화면 확대: Win + 더하기(+)로 확대, Win + 빼기(-)로 축소, Win + Esc로 원래대로. 마우스 포인터 둘레를 크게 보여 줘요. 바와 창 전체를 크게 하려면 빠른 설정의 화면 배율을 써요."

                SwitchRow {
                    title: "움직임 줄이기"
                    desc: "창과 패널이 열리고 닫힐 때 움직이지 않고 바로 바뀌어요."
                    checked: Theme.reduceMotion
                    onToggled: Theme.setReduceMotion(!Theme.reduceMotion)
                }

                SwitchRow {
                    title: "앱 글자 크게"
                    desc: "파일, 텍스트 편집기, 설정 같은 앱의 글자를 125%로 키워요."
                    checked: Theme.largeText
                    onToggled: Theme.setLargeText(!Theme.largeText)
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
        id: updatePage

        ColumnLayout {
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: 26
                implicitHeight: statusColumn.implicitHeight + 44
                radius: Theme.radius
                color: "transparent"
                border.width: 1
                border.color: Theme.border

                ColumnLayout {
                    id: statusColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 22
                    spacing: 6

                    Text {
                        text: root.updateTitle
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    Text {
                        visible: text !== ""
                        Layout.fillWidth: true
                        text: root.updateDetail
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        visible: root.upd.metered === true && root.updateAll > 0
                        Layout.fillWidth: true
                        text: "데이터 요금이 드는 연결(휴대폰 핫스팟 등)이에요. Wi-Fi에 연결한 뒤에 받는 걸 권해요."
                        color: Theme.destructive
                        font.family: Theme.font
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.topMargin: 10
                        spacing: 8

                        ActionButton {
                            visible: !ShellState.isLive && !root.updateChecking && root.updateAll > 0
                            text: "지금 업데이트"
                            onClicked: ShellState.runInTerminal("sudo robinctl update")
                        }

                        ActionButton {
                            visible: !ShellState.isLive
                            variant: "outline"
                            text: root.updateChecking ? "확인하는 중…" : "다시 확인"
                            onClicked: root.checkUpdates()
                        }
                    }
                }
            }

            Group {
                title: "업데이트 전에 스냅샷을 찍어요"
                hint: (root.upd.next_snapshot ?? 0) > 0 ? "이번에는 스냅샷 " + root.upd.next_snapshot + "번이에요. 문제가 생기면 컴퓨터를 켤 때 부팅 메뉴의 \"RobinOS snapshots\"에서 그 상태로 켜고 되돌려요."
                                                         : "문제가 생기면 컴퓨터를 켤 때 부팅 메뉴의 \"RobinOS snapshots\"에서 업데이트 직전 상태로 켜고 되돌려요."

                Text {
                    Layout.fillWidth: true
                    text: "스냅샷에는 시스템만 들어가요. 사진과 문서 같은 개인 파일은 백업 앱으로 따로 남겨요."
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }

            Group {
                title: "RobinOS 파일"
                hint: "화면, robinctl, 학습 미션은 RobinOS 패키지로 올라가요. 올라가면 화면이 새 버전으로 다시 떠요."
                visible: (root.upd.robinos ?? "") !== ""

                Text {
                    text: "버전 " + (root.upd.robinos ?? "")
                    color: Theme.fg
                    font.family: Theme.mono
                    font.pixelSize: 13
                }
            }
        }
    }

    Component {
        id: dateTimePage

        ColumnLayout {
            spacing: 0

            Group {
                title: "시간대"
                hint: "시계가 맞춰지는 지역이에요. 바꾸면 터미널에서 sudo timedatectl set-timezone이 실행되고 관리자 비밀번호를 물어요."

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 76
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
                                text: root.time.Timezone ? zonePicker.nameOf(root.time.Timezone) : "읽는 중이에요…"
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }

                            Text {
                                visible: text !== ""
                                text: root.time.Now ?? ""
                                color: Theme.muted
                                font.family: Theme.mono
                                font.pixelSize: 12
                            }
                        }

                        ActionButton {
                            variant: "outline"
                            text: "시간대 바꾸기"
                            onClicked: zonePicker.show()
                        }
                    }
                }
            }

            Group {
                title: "시간 맞추기"
                hint: "인터넷에서 시계를 맞춰요(systemd-timesyncd). 바꾸면 터미널에서 sudo timedatectl set-ntp가 실행돼요."

                SwitchRow {
                    title: "시간 자동 맞추기"
                    desc: root.time.NTP !== "yes" ? "꺼져 있어요. 시계가 조금씩 틀어질 수 있어요."
                          : root.time.NTPSynchronized === "yes" ? "인터넷의 시계와 맞춰져 있어요."
                                                                : "맞추는 중이에요. 인터넷에 연결돼 있어야 해요."
                    checked: root.time.NTP === "yes"
                    onToggled: ShellState.runInTerminal("sudo timedatectl set-ntp " + (root.time.NTP === "yes" ? "false" : "true") + " && timedatectl | head -n 6")
                }
            }

            Group {
                title: "하드웨어 시계"
                hint: "윈도우와 같이 쓰는 컴퓨터는 하드웨어 시계를 지역 시간으로 읽어서, 윈도우와 시간이 어긋나지 않아요."
                visible: root.time.LocalRTC === "yes"
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
