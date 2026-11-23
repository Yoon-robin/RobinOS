pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// RobinOS design tokens (robin-ui V5, assets/brand/robin-ui) and the user's appearance
// choices. The values come from assets/brand/robin-ui/tokens.json; docs/brand.md says
// which kit token each one is. Two grammars: menus (things on a face: windows, cards,
// rows, controls) and indicators (floating things: chips, toasts, notifications).
// One blue, no glass, no blur, no green or yellow.
Singleton {
    id: root

    readonly property bool dark: saved.dark

    // The one colour: on, chosen, link, progress, the window border
    readonly property color accent: dark ? "#4b7dfe" : "#3566e8"
    // The mark's tile (rk-mark): the same near-black in both themes
    readonly property color markBg: "#060a14"
    readonly property color accentSoft: dark ? Qt.rgba(75 / 255, 125 / 255, 254 / 255, 0.14) : Qt.rgba(53 / 255, 102 / 255, 232 / 255, 0.12)

    // Faces (menu grammar): side < page < card, split by 1px lines
    readonly property color side: dark ? "#0a0e11" : "#f4f5f7"
    readonly property color bg: dark ? "#0e1012" : "#ffffff"
    readonly property color surface: dark ? "#0f1115" : "#f8f8f9"
    // Controls: buttons, fields, tiles
    readonly property color raised: dark ? "#14151c" : "#f1f1f2"
    readonly property color secondary: dark ? "#14151c" : "#f1f1f2"
    readonly property color secondaryHover: dark ? "#1b1d25" : "#e9ecf0"
    readonly property color controlLineHover: dark ? "#32343b" : "#c6cad2"
    readonly property color controlPress: dark ? "#20222b" : "#dfe3e9"
    readonly property color chosen: dark ? "#222629" : "#dfe3e9"
    // The switch: a dark groove with a 1px line when off, blue with a white knob when on
    readonly property color switchOff: dark ? "#030913" : "#dedee3"
    readonly property color switchKnob: dark ? "#798895" : "#ffffff"
    readonly property color hover: dark ? "#15181b" : "#e9ecf0"
    readonly property color track: dark ? "#1c1e24" : "#e3e6eb"

    // Words: head (titles) > fg (text) > muted (soft) > subtle (faint)
    readonly property color head: dark ? "#f0f0f0" : "#000000"
    readonly property color fg: dark ? "#e6e7e9" : "#1a1a1a"
    readonly property color fgSoft: dark ? "#e6e7e9" : "#1a1a1a"
    readonly property color muted: dark ? "#8a8e94" : "#616161"
    readonly property color subtle: dark ? "#7d8187" : "#727272"

    readonly property color border: dark ? "#181a1d" : "#e3e6eb"
    readonly property color borderStrong: dark ? "#26272d" : "#dedee3"
    readonly property color input: dark ? "#26272d" : "#dedee3"

    // The filled button: blue with white words, one per screen
    readonly property color primary: dark ? "#3d6af0" : "#3566e8"
    readonly property color primaryHover: dark ? "#4b7dfe" : "#2f5cd6"
    readonly property color primaryFg: "#ffffff"
    readonly property color primaryMuted: dark ? "#26272d" : "#dedee3"
    readonly property color ring: dark ? Qt.rgba(75 / 255, 125 / 255, 254 / 255, 0.6) : Qt.rgba(53 / 255, 102 / 255, 232 / 255, 0.55)

    // Tones (indicator grammar): plain, on (blue), note (apricot), alarm (red).
    // Success is the blue: there is no green.
    readonly property color plain: dark ? "#98a4b8" : "#6b7480"
    readonly property color success: accent
    readonly property color note: dark ? "#c27463" : "#a4523f"
    readonly property color destructive: dark ? "#e5475a" : "#c0263a"
    readonly property color destructiveSolid: dark ? "#d52236" : "#c0263a"
    readonly property color destructiveSoft: dark ? Qt.rgba(213 / 255, 34 / 255, 54 / 255, 0.12) : Qt.rgba(192 / 255, 38 / 255, 58 / 255, 0.09)

    // The bar is the side column's face across the top; the dock and the floating
    // panels are indicators: the dark HUD face, a 1px line and a shadow all round
    readonly property color barBg: side
    readonly property color dockBg: panel
    readonly property color panel: dark ? "#08090b" : "#ffffff"
    readonly property color panelBorder: dark ? "#1c1e22" : "#dedee3"
    // Tiles and buttons inside a panel (quick settings)
    readonly property color tile: secondary
    readonly property color tileHover: secondaryHover
    readonly property color scrim: dark ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(0, 0, 0, 0.30)
    // Behind the launcher: the desktop stays in view, a little dimmer
    readonly property color scrimSoft: dark ? Qt.rgba(0, 0, 0, 0.28) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color shadow: dark ? Qt.rgba(0, 0, 0, 0.6) : Qt.rgba(20 / 255, 24 / 255, 30 / 255, 0.12)

    // Corners: chip 6, control 7, toast 10, card 12, window 14. Pills only on indicators.
    readonly property int radiusSm: 6
    readonly property int radiusMd: 7
    readonly property int radius: 12
    readonly property int radiusLg: 14
    readonly property int radiusTile: 12
    readonly property int radiusToast: 10
    readonly property int radiusPanel: 14
    readonly property int radiusDock: 14

    readonly property int barHeight: 36
    readonly property string font: "Pretendard Variable"
    // The kit's code font; Cascadia Mono is Cascadia Code without ligatures,
    // so ">>" and "->" in mission commands look the way they are typed
    readonly property string mono: "Cascadia Mono"
    // Pretendard at 450 / 550 / 650; never thinner
    readonly property int weight: 450
    readonly property int weightStrong: 550
    readonly property int weightHead: 650

    // "움직임 줄이기" (Settings.qml, T-161) turns the shell's animations off
    readonly property bool reduceMotion: saved.reduceMotion
    // "앱 글자 크게": GTK apps' text at 125% (the shell itself grows with 화면 배율)
    readonly property bool largeText: saved.largeText
    // Short motion: 150-240ms, coming in by 4px
    readonly property int durFast: reduceMotion ? 0 : 150
    readonly property int dur: reduceMotion ? 0 : 200
    readonly property int durSpring: reduceMotion ? 0 : 240

    // Set by robinos-session when there is no GPU acceleration (most VMs):
    // the shell then skips shadow effects.
    readonly property bool lowPower: Quickshell.env("ROBINOS_RENDER") === "software"

    function setDark(value) {
        saved.dark = value;
        store.writeAdapter();
        applySystem();
    }

    function setReduceMotion(value) {
        saved.reduceMotion = value;
        store.writeAdapter();
        applySystem();
    }

    function setLargeText(value) {
        saved.largeText = value;
        store.writeAdapter();
        applySystem();
    }

    // Push the choice to GTK/libadwaita, foot, qt6ct and Hyprland's window borders.
    function applySystem() {
        const scheme = dark ? "prefer-dark" : "default";
        const gtkTheme = dark ? "adw-gtk3-dark" : "adw-gtk3";
        const icons = dark ? "Papirus-Dark" : "Papirus";
        const palette = dark ? "RobinOS-Dark.conf" : "RobinOS-Light.conf";
        const footSignal = dark ? "USR1" : "USR2";
        const active = dark ? "rgba(32343bff)" : "rgba(c6cad2ff)";
        const inactive = dark ? "rgba(181a1dff)" : "rgba(e3e6ebff)";
        const background = dark ? "0xff0a0e11" : "0xfff4f5f7";

        const script = [
            "gsettings set org.gnome.desktop.interface color-scheme '" + scheme + "'",
            "gsettings set org.gnome.desktop.interface gtk-theme '" + gtkTheme + "'",
            "gsettings set org.gnome.desktop.interface icon-theme '" + icons + "'",
            "gsettings set org.gnome.desktop.interface accent-color 'blue'",
            "gsettings set org.gnome.desktop.interface enable-animations " + (reduceMotion ? "false" : "true"),
            "gsettings set org.gnome.desktop.interface text-scaling-factor " + (largeText ? "1.25" : "1.0"),
            "hyprctl eval 'hl.config({ animations = { enabled = " + (reduceMotion ? "false" : "true") + " } })'",
            "pkill -" + footSignal + " -x foot",
            // New foot windows: keep a small user config that includes the system one
            // and sets the starting theme (left alone once the user edits it).
            "f=\"${XDG_CONFIG_HOME:-$HOME/.config}/foot/foot.ini\"",
            "if [ ! -e \"$f\" ] || grep -q '^# robinos-managed' \"$f\"; then mkdir -p \"${f%/*}\""
                + " && printf '# robinos-managed\\n[main]\\ninclude=/etc/xdg/foot/foot.ini\\ninitial-color-theme=%s\\n' "
                + (dark ? "dark" : "light") + " > \"$f\"; fi",
            "conf=\"${XDG_CONFIG_HOME:-$HOME/.config}/qt6ct/qt6ct.conf\"",
            "[ -f \"$conf\" ] && sed -i"
                + " -e 's|^color_scheme_path=.*|color_scheme_path=/usr/share/robinos/qt6ct/" + palette + "|'"
                + " -e 's|^icon_theme=.*|icon_theme=" + icons + "|' \"$conf\"",
            "hyprctl eval 'hl.config({ general = { col = { active_border = \"" + active + "\", inactive_border = \""
                + inactive + "\" } }, misc = { background_color = " + background + " } })'"
        ].join("; ");

        Quickshell.execDetached(["sh", "-c", script + "; true"]);
    }

    FileView {
        id: store

        path: Quickshell.statePath("appearance.json")
        printErrors: false

        onLoaded: root.applySystem()

        JsonAdapter {
            id: saved

            property bool dark: true
            property bool reduceMotion: false
            property bool largeText: false
        }
    }
}
