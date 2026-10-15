import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// A list of time zones to choose from, over the window it sits in (anchors.fill
// parent): the common ones by their Korean names first, all of timedatectl's when
// the person searches. Used by the installer and the settings app.
//   picked(zone): a zone was chosen; closed(): dismissed without choosing
Item {
    id: root

    // The zone that has a check mark
    property string current: ""
    property bool open: false
    property var allZones: []

    signal picked(string zone)
    signal closed

    visible: open

    // Shown first, by the names people search for
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

    readonly property var matches: {
        const query = search.text.trim().toLowerCase();
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

    // "서울 (Asia/Seoul)"
    function nameOf(id) {
        const zone = commonZones.find(z => z.tz === id);
        return zone ? zone.name + " (" + id + ")" : id;
    }

    function show() {
        search.text = "";
        list.currentIndex = 0;
        open = true;
        search.input.forceActiveFocus();
        if (allZones.length === 0 && !zonesProc.running)
            zonesProc.running = true;
    }

    function choose(zone) {
        open = false;
        if (zone)
            picked(zone);
        else
            closed();
    }

    Process {
        id: zonesProc

        command: ["timedatectl", "list-timezones", "--no-pager"]
        stdout: StdioCollector {
            id: zonesOut
            onStreamFinished: root.allZones = zonesOut.text.split("\n").filter(line => line !== "")
        }
    }

    Keys.onEscapePressed: root.choose("")
    Keys.onUpPressed: list.decrementCurrentIndex()
    Keys.onDownPressed: list.incrementCurrentIndex()

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim

        MouseArea {
            anchors.fill: parent
            onClicked: root.choose("")
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
                    onClicked: root.choose("")
                }
            }

            InputField {
                id: search

                Layout.fillWidth: true
                placeholder: "도시나 지역 (예: 도쿄, New_York)"
                onAccepted: {
                    const zone = root.matches[list.currentIndex] ?? root.matches[0];
                    if (zone)
                        root.choose(zone.tz);
                }
                onTextChanged: list.currentIndex = 0
            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.matches
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index

                    width: list.width
                    height: 40
                    radius: Theme.radiusMd
                    color: index === list.currentIndex || rowMouse.containsMouse ? Theme.hover : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            visible: row.modelData.name !== ""
                            text: row.modelData.name
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 14
                        }

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.tz
                            color: row.modelData.name !== "" ? Theme.muted : Theme.fg
                            font.family: Theme.mono
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        Icon {
                            visible: row.modelData.tz === root.current
                            name: "check"
                            size: 14
                            color: Theme.fg
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.choose(row.modelData.tz)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.matches.length === 0
                text: "찾는 시간대가 없어요. 영어 도시 이름으로도 찾아봐요."
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }
        }
    }
}
