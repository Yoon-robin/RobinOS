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
    // Ticked on the confirm step: the files that go (the whole disk, or an
    // earlier RobinOS partition) and the BitLocker recovery key
    property bool eraseConfirmed: false
    property bool recoveryConfirmed: false
    property string timezone: "Asia/Seoul"
    property var allZones: []
    property bool zonePickerOpen: false
    property real percent: 0
    property string stage: ""
    property string errorText: ""
    property bool succeeded: false
    property var logLines: []
    property bool showLog: false
    property int tip: 0

    readonly property real gib: 1073741824
    readonly property real minSize: 40 * gib
    readonly property var disk: disks.find(d => d.path === diskPath) ?? null
    readonly property bool installing: step === 4
    // "alongside" goes into an earlier RobinOS partition when the disk has one
    // big enough: a reinstall, or a second try after an install that stopped
    readonly property string replacePath: mode === "alongside" && replaceable(disk) ? disk.robinos.path : ""
    // Windows ends up in the GRUB menu (robin-install decides the same way)
    readonly property bool dualBoot: disk !== null
                                     && ((mode === "alongside" && disk.windows)
                                         || disks.some(d => d.path !== diskPath && d.windows && d.esp && !d.removable))

    readonly property bool userValid: /^[a-z_][a-z0-9_-]{0,31}$/.test(userField.text) && userField.text !== "root"
    readonly property bool hostValid: /^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$/.test(hostField.text)
    readonly property bool passwordValid: passwordField.text.length > 0 && passwordField.text === password2Field.text

    readonly property bool canNext: {
        switch (step) {
        case 0:
            // Every package comes from the internet
            return ShellState.online;
        case 1:
            return disk !== null && (mode === "whole" ? disk.can_whole : mode === "alongside" && disk.can_alongside);
        case 2:
            return userValid && hostValid && passwordValid;
        case 3:
            if (mode === "whole")
                return eraseConfirmed;
            return (!(disk && disk.bitlocker) || recoveryConfirmed) && (replacePath === "" || eraseConfirmed);
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

    // Shown first in the time zone list, by the names people search for
    readonly property var commonZones: [
        { tz: "Asia/Seoul", name: "서울" },
        { tz: "Asia/Tokyo", name: "도쿄" },
        { tz: "Asia/Shanghai", name: "베이징, 상하이" },
        { tz: "Asia/Taipei", name: "타이베이" },
        { tz: "Asia/Singapore", name: "싱가포르" },
        { tz: "Asia/Ho_Chi_Minh", name: "호찌민" },
        { tz: "Australia/Sydney", name: "시드니" },
        { tz: "Pacific/Auckland", name: "오클랜드" },
        { tz: "Europe/London", name: "런던" },
        { tz: "Europe/Paris", name: "파리" },
        { tz: "Europe/Berlin", name: "베를린" },
        { tz: "America/New_York", name: "뉴욕 (미국 동부)" },
        { tz: "America/Chicago", name: "시카고 (미국 중부)" },
        { tz: "America/Denver", name: "덴버 (미국 산악)" },
        { tz: "America/Los_Angeles", name: "로스앤젤레스 (미국 서부)" },
        { tz: "America/Toronto", name: "토론토" },
        { tz: "America/Vancouver", name: "밴쿠버" },
        { tz: "Pacific/Honolulu", name: "호놀룰루" }
    ]

    readonly property var zoneMatches: {
        const query = zoneSearch.text.trim().toLowerCase();
        if (query === "")
            return commonZones;
        const seen = {};
        const found = [];
        const candidates = commonZones.concat(allZones.map(id => ({ tz: id, name: "" })));
        for (const zone of candidates) {
            if (seen[zone.tz] || !(zone.tz.toLowerCase().includes(query) || zone.name.includes(query)))
                continue;
            seen[zone.tz] = true;
            found.push(zone);
            if (found.length >= 100)
                break;
        }
        return found;
    }

    // What to know about RobinOS while the packages install
    readonly property var tips: [
        { title: "앱은 Win+Space로 찾아요", body: "메모장, 제어판처럼 윈도우에서 쓰던 이름으로 찾아도 나와요." },
        { title: "터미널이 리눅스 명령을 알려 줘요", body: "ipconfig를 치면 리눅스에서는 ip a라고 알려 주고, 직접 해 볼 학습 미션도 이어 줘요." },
        { title: "학습 센터에서 하나씩 익혀요", body: "미션 45개를 실제 터미널에서 풀어요. 채점은 robinctl이 해요." },
        { title: "업데이트 전에 스냅샷을 찍어요", body: "문제가 생기면 부팅 메뉴의 \"RobinOS snapshots\"에서 이전 상태로 켜고 되돌려요." },
        { title: "프로그램은 앱 스토어에서 받아요", body: ".exe 파일을 열면 리눅스에서 대신 쓸 앱을 알려 줘요." },
        { title: "단축키가 생각나지 않으면 Win+F1", body: "Alt+Tab, Win+E, Win+D처럼 윈도우 단축키가 대부분 그대로예요." }
    ]

    visible: ShellState.installerOpen
    title: "RobinOS 설치"
    implicitWidth: 800
    implicitHeight: 680
    minimumSize: Qt.size(680, 600)
    color: Theme.bg

    onVisibleChanged: {
        if (!visible) {
            ShellState.installerOpen = false;
        } else if (step === 0) {
            refreshDisks();
        }
    }

    function gb(bytes) {
        return Math.floor(bytes / gib) + "GB";
    }

    function diskLabel(d) {
        return (d.model !== "" ? d.model : "디스크") + " · " + gb(d.size);
    }

    function replaceable(d) {
        return d !== null && d.robinos !== undefined && d.robinos !== null && d.robinos.size >= minSize;
    }

    function zoneName(id) {
        const zone = commonZones.find(z => z.tz === id);
        return zone ? zone.name + " (" + id + ")" : id;
    }

    // The disk after the install, for the second bar
    function afterLayout(d) {
        if (d === null)
            return [];
        if (mode === "whole")
            return [{ kind: "efi", name: "EFI", size: gib, path: "" },
                    { kind: "new", name: "RobinOS", size: Math.max(d.size - gib, 0), path: "" }];
        let placed = false;
        return (d.layout ?? []).map(s => {
            const target = replacePath !== "" ? s.path === replacePath : s.kind === "free" && s.size === d.free;
            if (placed || !target)
                return s;
            placed = true;
            return { kind: "new", name: "RobinOS", size: s.size, path: s.path };
        });
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
        recoveryConfirmed = false;
        // Keep Windows by default when it is possible
        mode = d.can_alongside ? "alongside" : d.can_whole ? "whole" : "";
    }

    function chooseMode(key) {
        mode = key;
        eraseConfirmed = false;
    }

    function openZonePicker() {
        zoneSearch.text = "";
        zoneList.currentIndex = 0;
        zonePickerOpen = true;
        zoneSearch.input.forceActiveFocus();
        if (allZones.length === 0 && !zonesProc.running)
            zonesProc.running = true;
    }

    function pickZone(id) {
        if (id)
            timezone = id;
        zonePickerOpen = false;
        zoneButton.forceActiveFocus();
    }

    function next() {
        if (zonePickerOpen || !canNext)
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
        showLog = false;
        tip = 0;
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
        id: zonesProc

        command: ["timedatectl", "list-timezones", "--no-pager"]
        stdout: StdioCollector {
            id: zonesOut
            onStreamFinished: root.allZones = zonesOut.text.split("\n").filter(line => line !== "")
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
            const plan = {
                disk: root.diskPath,
                mode: root.mode,
                user: userField.text,
                password: passwordField.text,
                hostname: hostField.text,
                timezone: root.timezone
            };
            if (root.replacePath !== "")
                plan.replace = root.replacePath;
            if (root.mode === "alongside" && root.disk && root.disk.bitlocker)
                plan.bitlocker_key_saved = root.recoveryConfirmed;
            installProc.write(JSON.stringify(plan) + "\n");
            // robin-install reads the plan until end of input
            installProc.stdinEnabled = false;
        }
        onExited: (exitCode, exitStatus) => {
            root.succeeded = exitCode === 0 && root.errorText === "";
            if (!root.succeeded && root.errorText === "")
                root.errorText = "설치기가 오류로 끝났어요 (종료 코드 " + exitCode + ")";
            passwordField.text = "";
            password2Field.text = "";
            installProc.stdinEnabled = true;
            root.step = 5;
        }
    }

    // A new tip every few seconds while installing; pointing at it holds it
    Timer {
        interval: 9000
        repeat: true
        running: root.installing && !tipMouse.containsMouse
        onTriggered: root.tip = (root.tip + 1) % root.tips.length
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
                            ShellState.online
                                ? { icon: "check", ok: true, title: "인터넷에 연결돼 있어요",
                                    desc: "설치할 때 패키지를 내려받아요." }
                                : { icon: "wifi-off", ok: false, title: "인터넷에 연결해 주세요",
                                    desc: "패키지를 내려받아야 해서, 연결해야 다음으로 넘어가요. 빠른 설정(Win+S)에서 네트워크를 골라요." },
                            ShellState.unplugged
                                ? { icon: "battery", ok: false, title: "노트북을 전원에 연결해 주세요",
                                    desc: "설치하다 배터리가 다 되면 중간에 멈춰요. 설치에는 10분에서 30분쯤 걸려요." }
                                : ShellState.hasBattery
                                  ? { icon: "battery-charging", ok: true, title: "전원에 연결돼 있어요",
                                      desc: "설치에는 10분에서 30분쯤 걸려요." }
                                  : { icon: "history", ok: true, title: "설치에는 10분에서 30분쯤 걸려요",
                                      desc: "인터넷 속도에 따라 달라요." },
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
                Flickable {
                    id: whereFlick

                    clip: true
                    contentHeight: whereColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: whereColumn

                        width: whereFlick.width
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
                                                  + (diskCard.modelData.windows ? " · 윈도우 있음" + (diskCard.modelData.bitlocker ? " (BitLocker)" : "") : "")
                                                  + (diskCard.modelData.robinos ? " · 이전 RobinOS 있음" : "")
                                                  + (diskCard.modelData.free > 0 ? " · 빈 공간 " + root.gb(diskCard.modelData.free) : "")
                                            color: Theme.muted
                                            font.family: Theme.mono
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
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
                                { key: "alongside", enabled: root.disk.can_alongside,
                                  title: root.replaceable(root.disk)
                                         ? (root.disk.windows ? "윈도우 옆에 다시 설치" : "RobinOS 다시 설치")
                                         : "윈도우 옆에 설치",
                                  desc: root.replaceable(root.disk)
                                        ? "이전에 설치한 RobinOS 파티션(" + root.gb(root.disk.robinos.size) + ")에 다시 설치해요. 그 파티션의 파일만 지워지고"
                                          + (root.disk.windows ? " 윈도우와 파일은 그대로예요." : " 다른 파티션은 그대로예요.")
                                        : root.disk.can_alongside
                                          ? "빈 공간 " + root.gb(root.disk.free) + "에 설치해요. 윈도우와 파일은 그대로예요. 켤 때 부팅 메뉴에서 골라요."
                                          : root.disk.windows
                                            ? "빈 공간이 40GB보다 적어요. 윈도우의 '디스크 관리'에서 C: 드라이브를 '볼륨 축소'로 40GB 이상 줄인 뒤 다시 찾아 주세요."
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
                                    if (modelData.enabled)
                                        root.chooseMode(modelData.key);
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

                        // The disk now and after the install, partition by partition
                        DiskBar {
                            visible: root.disk !== null
                            Layout.topMargin: 10
                            caption: "지금"
                            segments: root.disk ? (root.disk.layout ?? []) : []
                        }

                        DiskBar {
                            visible: root.disk !== null && root.mode !== ""
                            caption: "설치하면"
                            segments: root.afterLayout(root.disk)
                        }
                    }
                }

                // 2. User and time zone
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

                    Text {
                        Layout.columnSpan: 2
                        Layout.topMargin: 10
                        text: "시간대"
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    // Opens the time zone list over the window
                    Rectangle {
                        id: zoneButton

                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: Theme.radiusMd
                        color: zoneMouse.containsMouse ? Theme.hover : "transparent"
                        border.width: 1
                        border.color: Theme.input

                        Accessible.role: Accessible.Button
                        Accessible.name: "시간대: " + root.zoneName(root.timezone) + ", 바꾸기"

                        activeFocusOnTab: true
                        Keys.onPressed: event => {
                            if (Keyboard.activates(event)) {
                                root.openZonePicker();
                                event.accepted = true;
                            }
                        }

                        FocusRing {
                            baseRadius: zoneButton.radius
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Icon {
                                name: "globe"
                                size: 15
                                color: Theme.fgSoft
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.zoneName(root.timezone)
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "바꾸기"
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            id: zoneMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openZonePicker()
                        }
                    }

                    Text {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        text: "시계가 이 시간대에 맞춰져요. 화면과 메뉴는 한국어예요."
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    Item {
                        Layout.columnSpan: 2
                        Layout.fillHeight: true
                    }
                }

                // 3. Confirm
                Flickable {
                    id: confirmFlick

                    clip: true
                    contentHeight: confirmColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: confirmColumn

                        width: confirmFlick.width
                        spacing: 10

                        Repeater {
                            model: [
                                { label: "디스크", value: root.disk ? root.diskLabel(root.disk) + " (" + root.disk.path + ")" : "" },
                                { label: "설치 방식", value: root.mode === "whole" ? "디스크 전체 사용"
                                                             : root.replacePath !== "" ? "이전 RobinOS 파티션에 다시 설치 (" + root.replacePath + ")"
                                                             : "윈도우 옆에 설치 (빈 공간 " + (root.disk ? root.gb(root.disk.free) : "") + ")" },
                                { label: "부팅 메뉴", value: root.dualBoot ? "RobinOS와 윈도우, 켤 때 골라요" : "RobinOS" },
                                { label: "사용자", value: userField.text },
                                { label: "컴퓨터 이름", value: hostField.text },
                                { label: "시간대", value: root.zoneName(root.timezone) },
                                { label: "언어", value: "한국어 (한글 입력은 한/영 키)" },
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

                        DiskBar {
                            Layout.topMargin: 6
                            caption: "설치하면"
                            segments: root.afterLayout(root.disk)
                        }

                        ConfirmBox {
                            visible: root.mode === "whole"
                            checked: root.eraseConfirmed
                            label: (root.disk ? root.disk.path : "") + "의 파일과 운영체제가 모두 지워지는 걸 이해했어요"
                            onToggled: root.eraseConfirmed = !root.eraseConfirmed
                        }

                        ConfirmBox {
                            visible: root.replacePath !== ""
                            checked: root.eraseConfirmed
                            label: "이전 RobinOS 파티션(" + root.replacePath + ")의 파일이 모두 지워지는 걸 이해했어요"
                            onToggled: root.eraseConfirmed = !root.eraseConfirmed
                        }

                        // A BitLocker drive asks for its recovery key once the boot
                        // order changes; without the key Windows' files are gone
                        ConfirmBox {
                            visible: root.mode === "alongside" && root.disk !== null && root.disk.bitlocker
                            checked: root.recoveryConfirmed
                            label: "윈도우 드라이브가 BitLocker로 잠겨 있어요. 설치한 뒤 윈도우가 복구 키를 물을 수 있어요. 복구 키(aka.ms/myrecoverykey)를 따로 적어 두었어요"
                            onToggled: root.recoveryConfirmed = !root.recoveryConfirmed
                        }
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

                    // One thing to know about RobinOS at a time
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 14
                        visible: !root.showLog
                        implicitHeight: tipColumn.implicitHeight + 40
                        radius: Theme.radiusLg
                        color: Theme.raised
                        border.width: 1
                        border.color: Theme.border

                        ColumnLayout {
                            id: tipColumn

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 20
                            spacing: 6

                            Text {
                                text: "설치하는 동안 알아 두면 좋은 것"
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }

                            Text {
                                id: tipTitle
                                Layout.fillWidth: true
                                text: root.tips[root.tip].title
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.tips[root.tip].body
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 14
                                lineHeight: 1.3
                                wrapMode: Text.WordWrap
                            }

                            Row {
                                Layout.topMargin: 8
                                spacing: 6

                                Repeater {
                                    model: root.tips.length

                                    Rectangle {
                                        required property int index
                                        width: index === root.tip ? 16 : 6
                                        height: 6
                                        radius: 3
                                        color: index === root.tip ? Theme.fg : Theme.borderStrong

                                        Behavior on width {
                                            NumberAnimation { duration: Theme.dur }
                                        }
                                    }
                                }
                            }
                        }

                        // Click for the next one
                        MouseArea {
                            id: tipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tip = (root.tip + 1) % root.tips.length
                        }
                    }

                    ActionButton {
                        variant: "ghost"
                        text: root.showLog ? "설치 기록 숨기기" : "설치 기록 보기"
                        onClicked: root.showLog = !root.showLog
                    }

                    LogBox {
                        visible: root.showLog
                        lines: root.logLines
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    Item {
                        visible: !root.showLog
                        Layout.fillHeight: true
                    }
                }

                // 5. Finished
                ColumnLayout {
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: root.succeeded
                              ? "다시 시작하면 RobinOS로 부팅돼요. USB는 컴퓨터가 꺼진 뒤 빼 주세요. 처음 켜면 환영 화면이 몇 가지를 안내해요."
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
                        text: "자세한 기록은 /var/log/robin-install.log에 있어요. 원인을 고친 뒤 \"처음으로\"를 누르면 다시 할 수 있어요. 윈도우 옆에 설치하다 멈췄다면 그때 만든 파티션에 다시 설치해요."
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }

                    LogBox {
                        visible: !root.succeeded
                        lines: root.logLines
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    Item {
                        visible: root.succeeded
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

        // ---- Time zone list, over the window ----
        Item {
            id: zonePicker

            anchors.fill: parent
            visible: root.zonePickerOpen

            Keys.onEscapePressed: root.pickZone("")
            Keys.onUpPressed: zoneList.decrementCurrentIndex()
            Keys.onDownPressed: zoneList.incrementCurrentIndex()

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.pickZone("")
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(440, parent.width - 64)
                height: Math.min(460, parent.height - 64)
                radius: Theme.radiusPanel
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                // Clicks on the card stay on the card
                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: "시간대 고르기"
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }

                        ActionButton {
                            variant: "ghost"
                            text: "닫기"
                            onClicked: root.pickZone("")
                        }
                    }

                    InputField {
                        id: zoneSearch
                        Layout.fillWidth: true
                        placeholder: "도시나 지역 (예: 도쿄, New_York)"
                        onAccepted: {
                            const zone = root.zoneMatches[zoneList.currentIndex] ?? root.zoneMatches[0];
                            if (zone)
                                root.pickZone(zone.tz);
                        }
                        onTextChanged: zoneList.currentIndex = 0
                    }

                    ListView {
                        id: zoneList

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: root.zoneMatches
                        boundsBehavior: Flickable.StopAtBounds
                        highlightMoveDuration: 0

                        delegate: Rectangle {
                            id: zoneRow

                            required property var modelData
                            required property int index

                            width: zoneList.width
                            height: 40
                            radius: Theme.radiusMd
                            color: index === zoneList.currentIndex || zoneRowMouse.containsMouse ? Theme.hover : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                Text {
                                    visible: zoneRow.modelData.name !== ""
                                    text: zoneRow.modelData.name
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: zoneRow.modelData.tz
                                    color: zoneRow.modelData.name !== "" ? Theme.muted : Theme.fg
                                    font.family: Theme.mono
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                Icon {
                                    visible: zoneRow.modelData.tz === root.timezone
                                    name: "check"
                                    size: 14
                                    color: Theme.fg
                                }
                            }

                            MouseArea {
                                id: zoneRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pickZone(zoneRow.modelData.tz)
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.zoneMatches.length === 0
                        text: "찾는 시간대가 없어요. 영어 도시 이름으로도 찾아봐요."
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    // A disk drawn as a bar of its partitions, with their names and sizes below
    component DiskBar: ColumnLayout {
        id: bar

        property string caption
        property var segments: []
        readonly property real total: segments.reduce((sum, s) => sum + s.size, 0)

        function colorOf(kind) {
            switch (kind) {
            case "new":
                return Theme.accent;
            case "robinos":
                return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4);
            case "windows":
                return Theme.primaryMuted;
            case "efi":
            case "system":
                return Theme.secondaryHover;
            case "free":
                return "transparent";
            default:
                return Theme.subtle;
            }
        }

        function sizeText(bytes) {
            return Math.floor(bytes / 1073741824) + "GB";
        }

        Layout.fillWidth: true
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.preferredWidth: 56
                text: bar.caption
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
            }

            Item {
                id: track

                Layout.fillWidth: true
                implicitHeight: 22
                clip: true

                Row {
                    anchors.fill: parent
                    spacing: 2

                    Repeater {
                        model: bar.segments

                        Rectangle {
                            required property var modelData

                            width: Math.max(4, (track.width - 2 * Math.max(bar.segments.length - 1, 0)) * modelData.size / Math.max(bar.total, 1))
                            height: track.height
                            radius: 4
                            color: bar.colorOf(modelData.kind)
                            border.width: modelData.kind === "free" ? 1 : 0
                            border.color: Theme.borderStrong
                        }
                    }
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 66
            spacing: 14

            Repeater {
                // Tiny partitions (Microsoft reserved, a 100 MB EFI) stay out of the legend
                model: bar.segments.filter(s => s.size >= 512 * 1048576 || s.kind === "new")

                Row {
                    id: legendItem

                    required property var modelData

                    spacing: 6

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 2
                        color: bar.colorOf(legendItem.modelData.kind)
                        border.width: legendItem.modelData.kind === "free" ? 1 : 0
                        border.color: Theme.borderStrong
                    }

                    Text {
                        text: (legendItem.modelData.kind === "new" ? "새 RobinOS" : legendItem.modelData.name) + " " + bar.sizeText(legendItem.modelData.size)
                        color: legendItem.modelData.kind === "new" ? Theme.fg : Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: legendItem.modelData.kind === "new" ? Font.Medium : Font.Normal
                    }
                }
            }
        }
    }

    // The installer's output, newest line at the bottom
    component LogBox: Rectangle {
        id: logBox

        property var lines: []

        radius: Theme.radiusMd
        color: Theme.raised
        border.width: 1
        border.color: Theme.border
        clip: true

        ListView {
            id: logView

            anchors.fill: parent
            anchors.margins: 10
            model: logBox.lines
            boundsBehavior: Flickable.StopAtBounds
            onCountChanged: positionViewAtEnd()
            Component.onCompleted: positionViewAtEnd()

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

    // A checkbox the person has to tick before installing, in the warning color
    component ConfirmBox: Rectangle {
        id: box

        property bool checked: false
        property string label: ""
        signal toggled

        Layout.fillWidth: true
        Layout.topMargin: 10
        implicitHeight: boxRow.implicitHeight + 24
        radius: Theme.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.destructive

        activeFocusOnTab: true
        Keys.onPressed: event => {
            if (Keyboard.activates(event)) {
                box.toggled();
                event.accepted = true;
            }
        }

        FocusRing {
            baseRadius: box.radius
        }

        RowLayout {
            id: boxRow

            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Rectangle {
                implicitWidth: 18
                implicitHeight: 18
                radius: Theme.radiusSm / 2
                color: box.checked ? Theme.destructive : "transparent"
                border.width: 1
                border.color: Theme.destructive

                Accessible.role: Accessible.CheckBox
                Accessible.name: box.label
                Accessible.checked: box.checked

                Icon {
                    anchors.centerIn: parent
                    visible: box.checked
                    name: "check"
                    size: 12
                    stroke: 3
                    color: "#ffffff"
                }
            }

            Text {
                Layout.fillWidth: true
                text: box.label
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
            onClicked: box.toggled()
        }
    }
}
