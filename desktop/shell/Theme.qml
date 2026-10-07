pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// RobinOS design tokens (shadcn/ui zinc palette) and the user's appearance choices.
// The same values live in docs/brand.md, foot.ini, hyprlock.conf and the qt6ct palettes.
Singleton {
    id: root

    readonly property bool dark: saved.dark
    readonly property string accentName: saved.accent

    readonly property var accents: ({
        "red": "#e5484d",
        "orange": "#f76b15",
        "green": "#30a46c",
        "blue": "#3e63dd",
        "violet": "#8e4ec6",
        "neutral": "#a1a1aa"
    })
    readonly property var accentLabels: ({
        "red": "Robin 레드",
        "orange": "오렌지",
        "green": "그린",
        "blue": "블루",
        "violet": "바이올렛",
        "neutral": "뉴트럴"
    })
    readonly property color accent: accents[accentName] ?? accents.red

    readonly property color bg: dark ? "#09090b" : "#ffffff"
    readonly property color surface: dark ? "#121214" : "#ffffff"
    readonly property color raised: dark ? "#18181b" : "#f4f4f5"
    readonly property color secondary: dark ? "#27272a" : "#f4f4f5"
    readonly property color secondaryHover: dark ? "#3f3f46" : "#e4e4e7"
    readonly property color hover: dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.05)
    readonly property color fg: dark ? "#fafafa" : "#09090b"
    readonly property color fgSoft: dark ? "#e4e4e7" : "#27272a"
    readonly property color muted: dark ? "#a1a1aa" : "#71717a"
    readonly property color subtle: dark ? "#71717a" : "#a1a1aa"
    readonly property color border: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.09)
    readonly property color borderStrong: dark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.16)
    readonly property color input: dark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color primary: dark ? "#fafafa" : "#18181b"
    readonly property color primaryFg: dark ? "#18181b" : "#fafafa"
    readonly property color primaryMuted: dark ? "#52525b" : "#a1a1aa"
    readonly property color ring: dark ? "#71717a" : "#a1a1aa"
    readonly property color success: dark ? "#4ade80" : "#16a34a"
    readonly property color destructive: dark ? "#f87171" : "#dc2626"
    readonly property color destructiveSolid: "#dc2626"
    readonly property color barBg: dark ? Qt.rgba(9 / 255, 9 / 255, 11 / 255, 0.72) : Qt.rgba(1, 1, 1, 0.78)
    readonly property color dockBg: dark ? Qt.rgba(18 / 255, 18 / 255, 20 / 255, 0.82) : Qt.rgba(1, 1, 1, 0.85)
    readonly property color scrim: dark ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(0, 0, 0, 0.25)
    readonly property color shadow: dark ? Qt.rgba(0, 0, 0, 0.7) : Qt.rgba(0, 0, 0, 0.18)

    readonly property int radiusSm: 6
    readonly property int radiusMd: 8
    readonly property int radius: 10
    readonly property int radiusLg: 14
    readonly property int radiusDock: 18

    readonly property int barHeight: 36
    readonly property string font: "Geist"
    readonly property string mono: "Geist Mono"

    readonly property int durFast: 120
    readonly property int dur: 180

    // Set by robinos-session when there is no GPU acceleration (most VMs):
    // the shell then skips shadow effects, and Hyprland turns off blur.
    readonly property bool lowPower: Quickshell.env("ROBINOS_RENDER") === "software"

    function setDark(value) {
        saved.dark = value;
        store.writeAdapter();
        applySystem();
    }

    function setAccent(name) {
        if (!(name in accents))
            return;
        saved.accent = name;
        store.writeAdapter();
        applySystem();
    }

    // Push the choice to GTK/libadwaita, foot, qt6ct and Hyprland's window borders.
    function applySystem() {
        const gnomeAccent = {
            "red": "red",
            "orange": "orange",
            "green": "green",
            "blue": "blue",
            "violet": "purple",
            "neutral": "slate"
        }[accentName] ?? "red";
        const scheme = dark ? "prefer-dark" : "default";
        const gtkTheme = dark ? "adw-gtk3-dark" : "adw-gtk3";
        const icons = dark ? "Papirus-Dark" : "Papirus";
        const palette = dark ? "RobinOS-Dark.conf" : "RobinOS-Light.conf";
        const footSignal = dark ? "USR1" : "USR2";
        const active = dark ? "rgba(ffffff38)" : "rgba(00000033)";
        const inactive = dark ? "rgba(ffffff14)" : "rgba(0000001a)";
        const background = dark ? "0xff09090b" : "0xffffffff";

        const script = [
            "gsettings set org.gnome.desktop.interface color-scheme '" + scheme + "'",
            "gsettings set org.gnome.desktop.interface gtk-theme '" + gtkTheme + "'",
            "gsettings set org.gnome.desktop.interface icon-theme '" + icons + "'",
            "gsettings set org.gnome.desktop.interface accent-color '" + gnomeAccent + "'",
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
            property string accent: "red"
        }
    }
}
