import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "holidays.js" as Holidays

// Month calendar under the bar's clock (click the clock or Super+Alt+D), like the
// Windows taskbar clock. Left/Right or the arrow buttons change the month, Home
// goes back to this month, Escape or a click outside closes it.
PanelWindow {
    id: root

    readonly property bool open: ShellState.calendarOpen
    property bool mapped: false
    property bool revealed: false
    // First day of the month on screen
    property var month: new Date()

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
    WlrLayershell.namespace: "robinos-calendar"
    // Only while open: during the fade-out the keyboard already goes back, so a window
    // started from here (a terminal, an app) gets the focus (boot test, 2026-10-10)
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onOpenChanged: {
        if (open) {
            thisMonth();
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
        ShellState.calendarOpen = false;
    }

    function thisMonth() {
        const now = ShellState.now;
        month = new Date(now.getFullYear(), now.getMonth(), 1);
    }

    function shift(months) {
        month = new Date(month.getFullYear(), month.getMonth() + months, 1);
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    // Six weeks from the Sunday on or before the 1st, so every month fits
    readonly property var days: {
        const first = new Date(month.getFullYear(), month.getMonth(), 1);
        const out = [];
        for (let i = 0; i < 42; i++)
            out.push(new Date(first.getFullYear(), first.getMonth(), 1 - first.getDay() + i));
        return out;
    }

    // This month's public holidays, listed under the days
    readonly property var monthHolidays: days.filter(d => d.getMonth() === month.getMonth() && Holidays.name(d) !== "")
        .map(d => (d.getMonth() + 1) + "월 " + d.getDate() + "일 " + "일월화수목금토"[d.getDay()] + "요일 · " + Holidays.name(d))

    // Click anywhere outside the card to close
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Theme.barHeight + 6
        width: 304
        height: content.implicitHeight + 28
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        opacity: root.revealed ? 1 : 0
        focus: true

        transform: Translate {
            y: root.revealed ? 0 : -6

            Behavior on y {
                NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic }
        }

        layer.enabled: !Theme.lowPower
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            shadowVerticalOffset: 12
        }

        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: root.shift(-1)
        Keys.onRightPressed: root.shift(1)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Home) {
                root.thisMonth();
                event.accepted = true;
            }
        }

        // Keep clicks inside the card from closing it
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10

            Text {
                text: ShellState.dateLong
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: root.month.getFullYear() + "년 " + (root.month.getMonth() + 1) + "월"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                IconButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    icon: "chevron-left"
                    label: "이전 달"
                    onClicked: root.shift(-1)
                }

                IconButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    icon: "chevron-right"
                    label: "다음 달"
                    onClicked: root.shift(1)
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 2
                columnSpacing: 2

                Repeater {
                    model: ShellState.weekdays

                    Text {
                        required property string modelData
                        required property int index

                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        // Sundays in red, as Korean calendars print them
                        color: index === 0 ? Theme.destructive : Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 12
                    }
                }

                Repeater {
                    model: root.days

                    Rectangle {
                        id: day

                        required property var modelData

                        readonly property bool inMonth: modelData.getMonth() === root.month.getMonth()
                        readonly property bool today: root.sameDay(modelData, ShellState.now)
                        readonly property string holiday: Holidays.name(modelData)

                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: Theme.radiusSm
                        color: today ? Theme.primary : "transparent"

                        Accessible.role: Accessible.StaticText
                        Accessible.name: (modelData.getMonth() + 1) + "월 " + modelData.getDate() + "일" + (today ? ", 오늘" : "") + (holiday !== "" ? ", " + holiday : "")

                        Text {
                            anchors.centerIn: parent
                            text: day.modelData.getDate()
                            color: day.today ? Theme.primaryFg
                                 : !day.inMonth ? Theme.subtle
                                 : day.modelData.getDay() === 0 || day.holiday !== "" ? Theme.destructive : Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.weight: day.today ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }

            // Red days, with their names (Sundays and holidays are red above)
            ColumnLayout {
                visible: root.monthHolidays.length > 0
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.topMargin: 4
                spacing: 4

                Repeater {
                    model: root.monthHolidays

                    RowLayout {
                        required property string modelData

                        spacing: 8

                        Rectangle {
                            implicitWidth: 6
                            implicitHeight: 6
                            radius: 3
                            color: Theme.destructive
                        }

                        Text {
                            text: modelData
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
