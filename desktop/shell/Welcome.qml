import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "keys.js" as Keyboard

// First-login welcome wizard: theme, 한/영 shortcut, a learning goal and a short
// shortcut tour. Opens until it is finished or skipped once (ShellState.welcome*);
// reopen it from the launcher ("환영 마법사") or with `qs ipc ... call shell welcome`.
PanelWindow {
    id: root

    readonly property bool open: ShellState.welcomeOpen
    property bool mapped: false
    property bool revealed: false
    property int step: 0
    property string goal: "basics"

    readonly property var steps: [
        { title: "RobinOS에 오신 걸 환영해요", desc: "윈도우에서 넘어와 매일 쓰는 컴퓨터예요. 쓰다 보면 리눅스와 보안 실력이 늘어요. 몇 가지만 고르면 바로 시작할 수 있어요." },
        { title: "화면 모양을 골라요", desc: "나중에 빠른 설정(Win+S)에서 언제든 바꿀 수 있어요." },
        { title: "한/영 전환 키를 골라요", desc: "한/영 키와 오른쪽 Alt로는 언제나 한/영을 바꿀 수 있어요. 함께 쓸 단축키를 하나 더 고르세요." },
        { title: "무엇부터 해 볼까요?", desc: "고른 것은 마지막에 바로 열려요. 나머지도 런처에서 언제든 시작할 수 있어요." },
        { title: "이것만 알면 돼요", desc: "윈도우에서 쓰던 단축키 대부분이 그대로 돼요. Win 키는 리눅스에서 Super 키라고 불러요." }
    ]
    readonly property bool last: step === steps.length - 1

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
    WlrLayershell.namespace: "robinos-welcome"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onOpenChanged: {
        if (open) {
            step = 0;
            goal = ShellState.welcomeGoal !== "" ? ShellState.welcomeGoal : "basics";
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

    onStepChanged: card.forceActiveFocus()

    Timer {
        id: hideTimer
        interval: Theme.dur
        onTriggered: {
            if (!root.open)
                root.mapped = false;
        }
    }

    function next() {
        if (last)
            ShellState.finishWelcome(goal);
        else
            step++;
    }

    function back() {
        if (step > 0)
            step--;
    }

    function skip() {
        ShellState.finishWelcome("");
    }

    readonly property string finishLabel: goal === "basics" ? "미션 시작하기" : goal === "web" ? "웹 랩 안내 보기" : "시작하기"

    // ---- UI ----

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.revealed ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic }
        }

        // Clicks outside the card do nothing; the wizard closes with its own buttons.
        MouseArea {
            anchors.fill: parent
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: 600
        height: column.implicitHeight
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        clip: true
        focus: true
        opacity: root.revealed ? 1 : 0
        scale: root.revealed ? 1 : 0.98

        Behavior on opacity {
            NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic }
        }

        layer.enabled: !Theme.lowPower
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            shadowVerticalOffset: 16
        }

        // Holding a key must not race through the steps (auto-repeat is ignored)
        Keys.onReturnPressed: event => {
            if (!event.isAutoRepeat)
                root.next();
        }
        Keys.onEnterPressed: event => {
            if (!event.isAutoRepeat)
                root.next();
        }
        Keys.onEscapePressed: event => {
            if (!event.isAutoRepeat)
                root.skip();
        }
        Keys.onRightPressed: event => {
            if (!event.isAutoRepeat && !root.last)
                root.step++;
        }
        Keys.onLeftPressed: event => {
            if (!event.isAutoRepeat)
                root.back();
        }

        ColumnLayout {
            id: column

            width: parent.width
            spacing: 0

            // ---- Header ----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.topMargin: 26
                spacing: 8

                Text {
                    text: (root.step + 1) + " / " + root.steps.length
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                Text {
                    Layout.fillWidth: true
                    text: root.steps[root.step].title
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: root.steps[root.step].desc
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 14
                    lineHeight: 1.3
                    wrapMode: Text.WordWrap
                }
            }

            // ---- Step content (the tallest step sets the height, so it doesn't jump) ----
            StackLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.topMargin: 22
                Layout.bottomMargin: 26
                currentIndex: root.step

                // 0. Welcome
                ColumnLayout {
                    spacing: 14

                    Repeater {
                        model: [
                            { icon: "grid", title: "익숙한 화면", desc: "아래 작업 표시줄, 자유롭게 띄우는 창, Alt+Tab이 윈도우와 같아요" },
                            { icon: "terminal", title: "조금씩 리눅스로", desc: "터미널에 윈도우 명령을 치면 같은 일을 하는 리눅스 명령을 알려 줘요" },
                            { icon: "shield", title: "안전한 실습", desc: "보안 실습은 내 컴퓨터 안의 랩에서만 열려요" }
                        ]

                        RowLayout {
                            id: feature

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
                                    name: feature.modelData.icon
                                    size: 17
                                    color: Theme.fgSoft
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: feature.modelData.title
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: feature.modelData.desc
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                // 1. Theme and accent
                ColumnLayout {
                    spacing: 18

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Repeater {
                            model: [
                                { dark: true, title: "다크" },
                                { dark: false, title: "라이트" }
                            ]

                            ColumnLayout {
                                id: themeChoice

                                required property var modelData
                                readonly property bool selected: Theme.dark === modelData.dark

                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                spacing: 8

                                Rectangle {
                                    id: themeTile

                                    Layout.fillWidth: true
                                    implicitHeight: 120
                                    radius: Theme.radius
                                    color: themeChoice.modelData.dark ? "#09090b" : "#ffffff"
                                    border.width: themeChoice.selected ? 2 : 1
                                    border.color: themeChoice.selected ? Theme.fg : Theme.border

                                    Accessible.role: Accessible.RadioButton
                                    Accessible.name: themeChoice.modelData.title
                                    Accessible.checked: themeChoice.selected

                                    activeFocusOnTab: true
                                    Keys.onPressed: event => {
                                        if (Keyboard.activates(event)) {
                                            Theme.setDark(themeChoice.modelData.dark);
                                            event.accepted = true;
                                        }
                                    }

                                    FocusRing {
                                        baseRadius: themeTile.radius
                                    }

                                    // Miniature desktop: bar, a window and the dock
                                    Rectangle {
                                        x: 10
                                        y: 10
                                        width: parent.width - 20
                                        height: 8
                                        radius: 3
                                        color: themeChoice.modelData.dark ? "#18181b" : "#f4f4f5"

                                        Rectangle {
                                            x: 4
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 6
                                            height: 6
                                            radius: 2
                                            color: Theme.accent
                                        }
                                    }

                                    Rectangle {
                                        x: parent.width * 0.22
                                        y: 28
                                        width: parent.width * 0.56
                                        height: 52
                                        radius: 4
                                        color: themeChoice.modelData.dark ? "#121214" : "#ffffff"
                                        border.width: 1
                                        border.color: themeChoice.modelData.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.12)
                                    }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 8
                                        width: 64
                                        height: 12
                                        radius: 4
                                        color: themeChoice.modelData.dark ? "#18181b" : "#f4f4f5"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Theme.setDark(themeChoice.modelData.dark)
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: themeChoice.modelData.title
                                    color: themeChoice.selected ? Theme.fg : Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            Layout.fillWidth: true
                            text: "강조 색상 · " + (Theme.accentLabels[Theme.accentName] ?? "")
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }

                        Repeater {
                            model: ["red", "orange", "green", "blue", "violet", "neutral"]

                            Rectangle {
                                id: swatch

                                required property string modelData
                                readonly property bool selected: Theme.accentName === modelData

                                implicitWidth: 26
                                implicitHeight: 26
                                radius: 13
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
                                    width: swatch.selected ? 16 : 22
                                    height: width
                                    radius: width / 2
                                    color: Theme.accents[swatch.modelData]

                                    Behavior on width {
                                        NumberAnimation { duration: Theme.durFast }
                                    }
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

                // 2. 한/영 shortcut, with a box to try it
                ColumnLayout {
                    spacing: 8

                    Repeater {
                        model: [
                            { key: "ctrl", title: "Ctrl + Space", desc: "기본값이에요" },
                            { key: "shift", title: "Shift + Space", desc: "윈도우 한국어 입력기에서 쓰던 방식이에요" },
                            { key: "none", title: "추가 단축키 없음", desc: "한/영 키와 오른쪽 Alt만 써요" }
                        ]

                        Rectangle {
                            id: imeChoice

                            required property var modelData
                            readonly property bool selected: ShellState.imeShortcut === modelData.key

                            Layout.fillWidth: true
                            implicitHeight: 52
                            radius: Theme.radius
                            color: imeMouse.containsMouse ? Theme.hover : "transparent"
                            border.width: 1
                            border.color: selected ? Theme.fg : Theme.border

                            Accessible.role: Accessible.RadioButton
                            Accessible.name: modelData.title
                            Accessible.checked: selected

                            activeFocusOnTab: true
                            Keys.onPressed: event => {
                                if (Keyboard.activates(event)) {
                                    ShellState.setImeShortcut(imeChoice.modelData.key);
                                    event.accepted = true;
                                }
                            }

                            FocusRing {
                                baseRadius: imeChoice.radius
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
                                    border.color: imeChoice.selected ? Theme.fg : Theme.borderStrong

                                    Rectangle {
                                        anchors.centerIn: parent
                                        visible: imeChoice.selected
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: Theme.fg
                                    }
                                }

                                Text {
                                    text: imeChoice.modelData.title
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: imeChoice.modelData.desc
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: imeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ShellState.setImeShortcut(imeChoice.modelData.key)
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        implicitHeight: 40
                        radius: Theme.radiusMd
                        color: "transparent"
                        border.width: 1
                        border.color: tryInput.activeFocus ? Theme.ring : Theme.input

                        TextInput {
                            id: tryInput

                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: imeChip.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.fg
                            selectionColor: Theme.secondaryHover
                            selectedTextColor: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 14
                            clip: true
                            activeFocusOnTab: true

                            Accessible.role: Accessible.EditableText
                            Accessible.name: "한/영 전환 연습"

                            // Enter here is for the input method, not "다음"
                            Keys.onReturnPressed: event => event.accepted = true
                            Keys.onEnterPressed: event => event.accepted = true

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: tryInput.text === "" && tryInput.preeditText === ""
                                text: "여기에 입력하며 한/영을 바꿔 보세요"
                                color: Theme.muted
                                font: tryInput.font
                            }
                        }

                        Rectangle {
                            id: imeChip

                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 26
                            implicitHeight: 24
                            radius: Theme.radiusSm
                            color: ShellState.hangul ? Theme.primary : Theme.secondary

                            Text {
                                anchors.centerIn: parent
                                text: ShellState.hangul ? "한" : "A"
                                color: ShellState.hangul ? Theme.primaryFg : Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                // 3. Learning goal
                ColumnLayout {
                    spacing: 8

                    Repeater {
                        model: [
                            { key: "basics", icon: "graduation-cap", title: "리눅스 기초", desc: "터미널에서 미션 5개를 풀며 기본 명령을 익혀요" },
                            { key: "web", icon: "flask", title: "웹 보안", desc: "내 컴퓨터 안의 Juice Shop과 DVWA로 연습해요" },
                            { key: "explore", icon: "globe", title: "먼저 둘러볼게요", desc: "학습은 나중에 런처에서 시작해도 돼요" }
                        ]

                        Rectangle {
                            id: goalChoice

                            required property var modelData
                            readonly property bool selected: root.goal === modelData.key

                            Layout.fillWidth: true
                            implicitHeight: 64
                            radius: Theme.radius
                            color: goalMouse.containsMouse ? Theme.hover : "transparent"
                            border.width: selected ? 2 : 1
                            border.color: selected ? Theme.fg : Theme.border

                            Accessible.role: Accessible.RadioButton
                            Accessible.name: modelData.title
                            Accessible.checked: selected

                            activeFocusOnTab: true
                            Keys.onPressed: event => {
                                if (Keyboard.activates(event)) {
                                    root.goal = goalChoice.modelData.key;
                                    event.accepted = true;
                                }
                            }

                            FocusRing {
                                baseRadius: goalChoice.radius
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
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
                                        name: goalChoice.modelData.icon
                                        size: 17
                                        color: Theme.fgSoft
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: goalChoice.modelData.title
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: goalChoice.modelData.desc
                                        color: Theme.muted
                                        font.family: Theme.font
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: goalMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.goal = goalChoice.modelData.key
                            }
                        }
                    }
                }

                // 4. Shortcut tour
                ColumnLayout {
                    spacing: 14

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 12

                        Repeater {
                            model: [
                                { keys: ["Win", "Space"], title: "런처: 앱과 명령 찾기" },
                                { keys: ["Win", "S"], title: "빠른 설정" },
                                { keys: ["Alt", "Tab"], title: "창 전환" },
                                { keys: ["Alt", "F4"], title: "창 닫기" },
                                { keys: ["Win", "E"], title: "파일" },
                                { keys: ["Win", "Enter"], title: "터미널" },
                                { keys: ["오른쪽 Alt"], title: "한/영 전환" },
                                { keys: ["Win", "L"], title: "화면 잠금" }
                            ]

                            RowLayout {
                                id: shortcut

                                required property var modelData

                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
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
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        text: "런처에서는 \"메모장\", \"제어판\"처럼 윈도우 이름으로 찾아도 돼요. 이 안내는 런처의 \"환영 마법사\"로 다시 볼 수 있어요."
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 13
                        lineHeight: 1.3
                        wrapMode: Text.WordWrap
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

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 28
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Repeater {
                        model: root.steps.length

                        Rectangle {
                            required property int index

                            width: index === root.step ? 18 : 6
                            height: 6
                            radius: 3
                            color: index === root.step ? Theme.fg : Theme.borderStrong

                            Behavior on width {
                                NumberAnimation { duration: Theme.durFast }
                            }
                        }
                    }
                }

                RowLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    ActionButton {
                        visible: !root.last
                        variant: "ghost"
                        text: "건너뛰기"
                        onClicked: root.skip()
                    }

                    ActionButton {
                        visible: root.step > 0
                        variant: "outline"
                        text: "이전"
                        onClicked: root.back()
                    }

                    ActionButton {
                        text: root.last ? root.finishLabel : "다음"
                        onClicked: root.next()
                    }
                }
            }
        }
    }
}
