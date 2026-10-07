import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "keys.js" as Keyboard

// Graphical installer for the live session: a regular window that collects the
// choices and runs `sudo robin-install run -` (installer/robin-install) with the
// plan on stdin, showing its "@@ <percent> <message>" lines as progress.
// Opened from the launcher ("RobinOS 설치") or `qs ipc ... call shell installer`.
FloatingWindow {
    id: root

    // 0 intro, 1 where, 2 user, 3 confirm, 4 installing, 5 finished
    property int step: 0
    property var disks: []
    property bool disksLoading: false
    property string diskPath: ""
    property string mode: ""
    property bool eraseConfirmed: false
    property real percent: 0
    property string stage: ""
    property string errorText: ""
    property bool succeeded: false
    property var logLines: []

    readonly property var disk: disks.find(d => d.path === diskPath) ?? null
    readonly property bool installing: step === 4

    readonly property bool userValid: /^[a-z_][a-z0-9_-]{0,31}$/.test(userField.text) && userField.text !== "root"
    readonly property bool hostValid: /^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$/.test(hostField.text)
    readonly property bool passwordValid: passwordField.text.length > 0 && passwordField.text === password2Field.text

    readonly property bool canNext: {
        switch (step) {
        case 0:
            return true;
        case 1:
            return disk !== null && (mode === "whole" ? disk.can_whole : mode === "alongside" && disk.can_alongside);
        case 2:
            return userValid && hostValid && passwordValid;
        case 3:
            return mode === "alongside" || eraseConfirmed;
        default:
            return false;
        }
    }

    readonly property var titles: [
        "RobinOS를 이 컴퓨터에 설치해요",
        "어디에 설치할까요?",
        "사용자를 만들어요",
        "설치 준비가 끝났어요",
        "설치하는 중이에요",
        ""
    ]

    visible: ShellState.installerOpen
    title: "RobinOS 설치"
    implicitWidth: 760
    implicitHeight: 600
    minimumSize: Qt.size(680, 560)
    color: Theme.bg

    onVisibleChanged: {
        if (!visible) {
            ShellState.installerOpen = false;
        } else if (step === 0) {
            refreshDisks();
        }
    }

    function gb(bytes) {
        return Math.floor(bytes / 1073741824) + "GB";
    }

    function diskLabel(d) {
        return (d.model !== "" ? d.model : "디스크") + " · " + gb(d.size);
    }

    function refreshDisks() {
        if (disksProc.running)
            return;
        disksLoading = true;
        disksProc.running = true;
    }

    function chooseDisk(d) {
        diskPath = d.path;
        eraseConfirmed = false;
        // Keep Windows by default when it is possible
        mode = d.can_alongside ? "alongside" : d.can_whole ? "whole" : "";
    }

    function next() {
        if (!canNext)
            return;
        if (step === 3)
            startInstall();
        else
            step++;
    }

    function back() {
        if (step > 0 && step < 4)
            step--;
    }

    function startInstall() {
        percent = 0;
        stage = "설치를 시작해요";
        errorText = "";
        succeeded = false;
        logLines = [];
        step = 4;
        installProc.running = true;
    }

    function handleLine(line) {
        const progressLine = line.match(/^@@ (\d+) (.*)$/);
        const errorLine = line.match(/^@@ error (.*)$/);
        if (errorLine) {
            errorText = errorLine[1];
        } else if (progressLine) {
            percent = parseInt(progressLine[1]) / 100;
            stage = progressLine[2];
        }
        const lines = logLines.concat([line]);
        logLines = lines.length > 400 ? lines.slice(lines.length - 400) : lines;
    }

    Process {
        id: disksProc

        command: ["sudo", "-n", "robin-install", "disks"]
        stdout: StdioCollector {
            id: disksOut
            onStreamFinished: {
                try {
                    root.disks = JSON.parse(disksOut.text);
                } catch (error) {
                    root.disks = [];
                }
                root.disksLoading = false;
                const current = root.disk;
                if (current)
                    root.chooseDisk(current);
                else if (root.disks.length > 0)
                    root.chooseDisk(root.disks[0]);
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.disksLoading = false;
        }
    }

    Process {
        id: installProc

        command: ["sudo", "-n", "robin-install", "run", "-"]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => root.handleLine(data)
        }
        stderr: SplitParser {
            onRead: data => root.handleLine(data)
        }
        onStarted: {
            installProc.write(JSON.stringify({
                disk: root.diskPath,
                mode: root.mode,
                user: userField.text,
                password: passwordField.text,
                hostname: hostField.text,
                timezone: "Asia/Seoul"
            }) + "\n");
            // robin-install reads the plan until end of input
            installProc.stdinEnabled = false;
        }
        onExited: (exitCode, exitStatus) => {
            root.succeeded = exitCode === 0 && root.errorText === "";
            if (!root.succeeded && root.errorText === "")
                root.errorText = "설치기가 종료 코드 " + exitCode + "로 끝났어요";
            passwordField.text = "";
            password2Field.text = "";
            installProc.stdinEnabled = true;
            root.step = 5;
        }
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onReturnPressed: event => {
            if (!event.isAutoRepeat)
                root.next();
        }
        Keys.onEnterPressed: event => {
            if (!event.isAutoRepeat)
                root.next();
        }

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
                        text: root.step < 4 ? (root.step + 1) + " / 4" : "RobinOS 설치"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.step === 5 ? (root.succeeded ? "설치가 끝났어요" : "설치하지 못했어요") : root.titles[root.step]
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }
            }

            // ---- Steps ----
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 32
                Layout.rightMargin: 32
                Layout.topMargin: 20
                Layout.bottomMargin: 20
                currentIndex: root.step

                // 0. Before you start
                ColumnLayout {
                    spacing: 14

                    Text {
                        Layout.fillWidth: true
                        text: "몇 가지만 고르면 나머지는 설치기가 알아서 해요. 설치하는 동안에도 이 라이브 화면은 그대로 쓸 수 있어요."
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 14
                        lineHeight: 1.3
                        wrapMode: Text.WordWrap
                    }

                    Repeater {
                        model: [
                            { icon: ShellState.online ? "check" : "wifi-off", ok: ShellState.online,
                              title: ShellState.online ? "인터넷에 연결돼 있어요" : "인터넷에 연결해 주세요",
                              desc: "설치할 때 패키지를 내려받아요. 빠른 설정(Super+S)에서 네트워크를 연결할 수 있어요." },
                            { icon: "battery-charging", ok: true, title: "노트북은 전원에 연결해 두세요",
                              desc: "설치에는 10분에서 30분쯤 걸려요." },
                            { icon: "shield", ok: true, title: "중요한 파일은 먼저 백업하세요",
                              desc: "디스크 전체에 설치하면 그 디스크의 파일이 모두 지워져요." }
                        ]

                        RowLayout {
                            id: check

                            required property var modelData

                            Layout.fillWidth: true
                            spacing: 14

                            Rectangle {
                                implicitWidth: 36
                                implicitHeight: 36
                                radius: Theme.radiusMd
                                color: Theme.raised
                                border.width: 1
                                border.color: Theme.border

                                Icon {
                                    anchors.centerIn: parent
                                    name: check.modelData.icon
                                    size: 17
                                    color: check.modelData.ok ? Theme.fgSoft : Theme.destructive
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: check.modelData.title
                                    color: check.modelData.ok ? Theme.fg : Theme.destructive
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: check.modelData.desc
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // 1. Disk and mode
                ColumnLayout {
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: root.disksLoading ? "디스크를 찾는 중이에요…" : root.disks.length === 0 ? "설치할 수 있는 디스크가 없어요" : "설치할 디스크를 고르세요"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 13
                        }

                        ActionButton {
                            variant: "ghost"
                            text: "다시 찾기"
                            onClicked: root.refreshDisks()
                        }
                    }

                    Repeater {
                        model: root.disks

                        Rectangle {
                            id: diskCard

                            required property var modelData
                            readonly property bool selected: root.diskPath === modelData.path

                            Layout.fillWidth: true
                            implicitHeight: 60
                            radius: Theme.radius
                            color: diskMouse.containsMouse ? Theme.hover : "transparent"
                            border.width: selected ? 2 : 1
                            border.color: selected ? Theme.fg : Theme.border

                            Accessible.role: Accessible.RadioButton
                            Accessible.name: root.diskLabel(modelData)
                            Accessible.checked: selected

                            activeFocusOnTab: true
                            Keys.onPressed: event => {
                                if (Keyboard.activates(event)) {
                                    root.chooseDisk(diskCard.modelData);
                                    event.accepted = true;
                                }
                            }

                            FocusRing {
                                baseRadius: diskCard.radius
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 14

                                Icon {
                                    name: "hard-drive"
                                    size: 20
                                    color: Theme.fgSoft
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.diskLabel(diskCard.modelData)
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: diskCard.modelData.path
                                              + (diskCard.modelData.windows ? " · 윈도우 있음" : "")
                                              + (diskCard.modelData.free > 0 ? " · 빈 공간 " + root.gb(diskCard.modelData.free) : "")
                                        color: Theme.muted
                                        font.family: Theme.mono
                                        font.pixelSize: 12
                                    }
                                }
                            }

                            MouseArea {
                                id: diskMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.chooseDisk(diskCard.modelData)
                            }
                        }
                    }

                    Text {
                        visible: root.disk !== null
                        Layout.topMargin: 8
                        text: "설치 방식"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 13
                    }

                    Repeater {
                        model: root.disk === null ? [] : [
                            { key: "alongside", enabled: root.disk.can_alongside, title: "윈도우 옆에 설치",
                              desc: root.disk.can_alongside
                                    ? "빈 공간 " + root.gb(root.disk.free) + "에 설치해요. 윈도우와 파일은 그대로예요. 켤 때 부팅 메뉴에서 골라요."
                                    : root.disk.windows
                                      ? "빈 공간이 40GB보다 적어요. 윈도우의 '디스크 관리'에서 '볼륨 축소'로 40GB 이상 비운 뒤 다시 찾아 주세요."
                                      : "윈도우가 있고 빈 공간이 40GB 이상인 디스크에서 쓸 수 있어요." },
                            { key: "whole", enabled: root.disk.can_whole, title: "디스크 전체 사용",
                              desc: root.disk.can_whole ? "이 디스크의 모든 파일과 운영체제가 지워지고 RobinOS만 남아요."
                                                        : "40GB보다 작은 디스크에는 설치할 수 없어요." }
                        ]

                        Rectangle {
                            id: modeCard

                            required property var modelData
                            readonly property bool selected: root.mode === modelData.key

                            Layout.fillWidth: true
                            implicitHeight: modeColumn.implicitHeight + 24
                            radius: Theme.radius
                            color: modeMouse.containsMouse && modelData.enabled ? Theme.hover : "transparent"
                            border.width: 1
                            border.color: selected ? Theme.fg : Theme.border
                            opacity: modelData.enabled ? 1 : 0.55

                            Accessible.role: Accessible.RadioButton
                            Accessible.name: modelData.title
                            Accessible.checked: selected

                            function choose() {
                                if (modelData.enabled) {
                                    root.mode = modelData.key;
                                    root.eraseConfirmed = false;
                                }
                            }

                            activeFocusOnTab: modelData.enabled
                            Keys.onPressed: event => {
                                if (Keyboard.activates(event)) {
                                    modeCard.choose();
                                    event.accepted = true;
                                }
                            }

                            FocusRing {
                                baseRadius: modeCard.radius
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 12

                                Rectangle {
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: 14
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    radius: 8
                                    color: "transparent"
                                    border.width: 1
                                    border.color: modeCard.selected ? Theme.fg : Theme.borderStrong

                                    Rectangle {
                                        anchors.centerIn: parent
                                        visible: modeCard.selected
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: Theme.fg
                                    }
                                }

                                ColumnLayout {
                                    id: modeColumn

                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: modeCard.modelData.title
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modeCard.modelData.desc
                                        color: modeCard.modelData.key === "whole" && modeCard.selected ? Theme.destructive : Theme.muted
                                        font.family: Theme.font
                                        font.pixelSize: 13
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            MouseArea {
                                id: modeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: modeCard.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: modeCard.choose()
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // 2. User
                GridLayout {
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 6

                    Text {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                        text: "이 계정으로 로그인하고, 관리자 작업(sudo)도 이 비밀번호로 해요."
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                    }

                    Text { text: "사용자 이름"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }
                    Text { text: "컴퓨터 이름"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }

                    InputField {
                        id: userField
                        Layout.fillWidth: true
                        placeholder: "예: robin"
                        invalid: text !== "" && !root.userValid
                        onAccepted: root.next()
                    }

                    InputField {
                        id: hostField
                        Layout.fillWidth: true
                        text: "robinos"
                        placeholder: "robinos"
                        invalid: !root.hostValid
                        onAccepted: root.next()
                    }

                    Text {
                        Layout.fillWidth: true
                        text: userField.text !== "" && !root.userValid ? "영어 소문자로 시작하고 소문자, 숫자, -, _만 써요" : "영어 소문자로 써요"
                        color: userField.text !== "" && !root.userValid ? Theme.destructive : Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 12
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.hostValid ? "네트워크에서 보이는 이름이에요" : "영어, 숫자, -만 써요"
                        color: root.hostValid ? Theme.muted : Theme.destructive
                        font.family: Theme.font
                        font.pixelSize: 12
                    }

                    Text { Layout.topMargin: 10; text: "비밀번호"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }
                    Text { Layout.topMargin: 10; text: "비밀번호 확인"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }

                    InputField {
                        id: passwordField
                        Layout.fillWidth: true
                        password: true
                        placeholder: "비밀번호"
                        onAccepted: root.next()
                    }

                    InputField {
                        id: password2Field
                        Layout.fillWidth: true
                        password: true
                        placeholder: "한 번 더"
                        invalid: text !== "" && text !== passwordField.text
                        onAccepted: root.next()
                    }

                    Text {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        text: password2Field.text !== "" && password2Field.text !== passwordField.text ? "두 비밀번호가 달라요" : ""
                        color: Theme.destructive
                        font.family: Theme.font
                        font.pixelSize: 12
                    }

                    Item {
                        Layout.columnSpan: 2
                        Layout.fillHeight: true
                    }
                }

                // 3. Confirm
                ColumnLayout {
                    spacing: 10

                    Repeater {
                        model: [
                            { label: "디스크", value: root.disk ? root.diskLabel(root.disk) + " (" + root.disk.path + ")" : "" },
                            { label: "설치 방식", value: root.mode === "whole" ? "디스크 전체 사용" : "윈도우 옆에 설치 (빈 공간 " + (root.disk ? root.gb(root.disk.free) : "") + ")" },
                            { label: "사용자", value: userField.text },
                            { label: "컴퓨터 이름", value: hostField.text },
                            { label: "시간대와 언어", value: "서울 (Asia/Seoul), 한국어" },
                            { label: "스냅샷", value: "업데이트 전후 자동, 부팅 메뉴에서 되돌리기" }
                        ]

                        RowLayout {
                            id: summaryRow

                            required property var modelData

                            Layout.fillWidth: true
                            spacing: 16

                            Text {
                                Layout.preferredWidth: 110
                                text: summaryRow.modelData.label
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 13
                            }

                            Text {
                                Layout.fillWidth: true
                                text: summaryRow.modelData.value
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        id: eraseBox

                        visible: root.mode === "whole"
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        implicitHeight: warnRow.implicitHeight + 24
                        radius: Theme.radius
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.destructive

                        activeFocusOnTab: true
                        Keys.onPressed: event => {
                            if (Keyboard.activates(event)) {
                                root.eraseConfirmed = !root.eraseConfirmed;
                                event.accepted = true;
                            }
                        }

                        FocusRing {
                            baseRadius: eraseBox.radius
                        }

                        RowLayout {
                            id: warnRow

                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Rectangle {
                                implicitWidth: 18
                                implicitHeight: 18
                                radius: Theme.radiusSm / 2
                                color: root.eraseConfirmed ? Theme.destructive : "transparent"
                                border.width: 1
                                border.color: Theme.destructive

                                Accessible.role: Accessible.CheckBox
                                Accessible.name: "데이터가 지워지는 걸 이해했어요"
                                Accessible.checked: root.eraseConfirmed

                                Icon {
                                    anchors.centerIn: parent
                                    visible: root.eraseConfirmed
                                    name: "check"
                                    size: 12
                                    stroke: 3
                                    color: "#ffffff"
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (root.disk ? root.disk.path : "") + "의 파일과 운영체제가 모두 지워지는 걸 이해했어요"
                                color: Theme.destructive
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                wrapMode: Text.WordWrap
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.eraseConfirmed = !root.eraseConfirmed
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // 4. Installing
                ColumnLayout {
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: root.stage
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            text: Math.round(root.percent * 100) + "%"
                            color: Theme.muted
                            font.family: Theme.mono
                            font.pixelSize: 13
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 8
                        radius: 4
                        color: Theme.secondary

                        Accessible.role: Accessible.ProgressBar
                        Accessible.name: "설치 진행률"

                        Rectangle {
                            width: parent.width * root.percent
                            height: parent.height
                            radius: 4
                            color: Theme.accent

                            Behavior on width {
                                NumberAnimation { duration: Theme.dur }
                            }
                        }
                    }

                    Text {
                        Layout.topMargin: 6
                        text: "설치기가 실행하는 명령"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 12
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.radiusMd
                        color: Theme.raised
                        border.width: 1
                        border.color: Theme.border
                        clip: true

                        ListView {
                            id: logView

                            anchors.fill: parent
                            anchors.margins: 10
                            model: root.logLines
                            boundsBehavior: Flickable.StopAtBounds
                            onCountChanged: positionViewAtEnd()

                            delegate: Text {
                                required property string modelData
                                width: logView.width
                                text: modelData
                                color: modelData.startsWith("$ ") ? Theme.fg : Theme.muted
                                font.family: Theme.mono
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // 5. Finished
                ColumnLayout {
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: root.succeeded
                              ? "다시 시작하면 RobinOS로 부팅돼요. USB나 설치 디스크는 컴퓨터가 꺼진 뒤 빼 주세요."
                              : root.errorText
                        color: root.succeeded ? Theme.muted : Theme.destructive
                        font.family: Theme.font
                        font.pixelSize: 14
                        lineHeight: 1.3
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        visible: !root.succeeded
                        Layout.fillWidth: true
                        text: "자세한 기록은 /var/log/robin-install.log에 있어요. 원인을 고친 뒤 처음부터 다시 할 수 있어요."
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            // ---- Footer ----
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                color: Theme.raised

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 1
                    color: Theme.border
                }

                RowLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    ActionButton {
                        visible: root.step < 4
                        variant: "ghost"
                        text: "닫기"
                        onClicked: ShellState.installerOpen = false
                    }

                    ActionButton {
                        visible: root.step > 0 && root.step < 4
                        variant: "outline"
                        text: "이전"
                        onClicked: root.back()
                    }

                    ActionButton {
                        visible: root.step < 4
                        text: root.step === 3 ? "설치 시작" : "다음"
                        opacity: root.canNext ? 1 : 0.5
                        onClicked: root.next()
                    }

                    ActionButton {
                        visible: root.step === 5 && !root.succeeded
                        variant: "outline"
                        text: "처음으로"
                        onClicked: {
                            root.step = 0;
                            root.refreshDisks();
                        }
                    }

                    ActionButton {
                        visible: root.step === 5 && root.succeeded
                        variant: "outline"
                        text: "나중에"
                        onClicked: ShellState.installerOpen = false
                    }

                    ActionButton {
                        visible: root.step === 5 && root.succeeded
                        text: "다시 시작"
                        onClicked: ShellState.reboot()
                    }
                }
            }
        }
    }
}
