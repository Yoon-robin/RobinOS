#!/usr/bin/env python3
"""Checks that RobinOS screens stay inside the robin-ui V5 kit (docs/brand.md).

assets/brand/robin-ui/tokens.json is the source of the values. This checks:
  - every colour written in desktop/shell/Theme.qml and the system screens
    (lock, login, boot menus) is a kit colour
  - shell QML outside Theme.qml writes no colour of its own except kit colours
    (the theme previews draw the other theme's faces), no Font.* weight (the kit's
    450/550/650 are Theme.weight*) and no overshooting spring (Easing.OutBack)
  - no green or yellow anywhere in those files
  - Theme.qml's corners are the kit's (6, 7, 10, 12, 14)
  - Hyprland blurs no shell surface and the lock screen blurs nothing behind it
    (the kit has no glass)

Run from the repository root: python3 scripts/check-kit.py
"""

import colorsys
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOKENS = ROOT / "assets/brand/robin-ui/tokens.json"
SHELL = ROOT / "desktop/shell"
SYSTEM_SCREENS = [
    "desktop/hypr/hyprlock.conf",
    "themes/sddm/robinos/Main.qml",
    "themes/sddm/robinos/theme.conf",
    "themes/grub/robinos/theme.txt",
    "themes/syslinux/colors.cfg",
]
KIT_CORNERS = {6, 7, 10, 12, 14}

failures = []


def fail(msg):
    failures.append(msg)
    print(f"  FAIL    {msg}")


def ok(msg):
    print(f"  ok      {msg}")


def kit_colours():
    data = json.loads(TOKENS.read_text(encoding="utf-8"))
    out = {"ffffff", "000000"}
    for theme in data.values():
        for value in theme.values():
            for m in re.finditer(r"#([0-9a-fA-F]{6})\b", str(value)):
                out.add(m.group(1).lower())
            # rgb(75 125 254 / 14%) style values
            for m in re.finditer(r"rgb\((\d+) (\d+) (\d+)", str(value)):
                out.add("".join(f"{int(c):02x}" for c in m.groups()))
    return out


def hex_colours(text):
    """6-digit colours in #rrggbb, #aarrggbb, rgba(rrggbbaa) and 0xffrrggbb forms."""
    found = []
    for m in re.finditer(r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b", text):
        h = m.group(1).lower()
        found.append(h[2:] if len(h) == 8 else h)
    for m in re.finditer(r"rgba\(([0-9a-fA-F]{6})(?:[0-9a-fA-F]{2})?\)", text):
        found.append(m.group(1).lower())
    for m in re.finditer(r"0x[0-9a-fA-F]{2}([0-9a-fA-F]{6})\b", text):
        found.append(m.group(1).lower())
    return found


def green_or_yellow(h):
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    hue, light, sat = colorsys.rgb_to_hls(r, g, b)
    return sat > 0.3 and 0.25 < light < 0.9 and 45 / 360 <= hue <= 170 / 360


def check_file_colours(path, kit, label):
    text = path.read_text(encoding="utf-8")
    bad = sorted({h for h in hex_colours(text) if h not in kit})
    greens = sorted({h for h in hex_colours(text) if green_or_yellow(h)})
    if bad:
        fail(f"{label}: colours outside the kit: {', '.join('#' + h for h in bad)}")
    if greens:
        fail(f"{label}: green or yellow: {', '.join('#' + h for h in greens)}")
    if not bad and not greens:
        ok(f"{label}: kit colours only")


def main():
    kit = kit_colours()
    print("robin-ui V5 kit")

    check_file_colours(SHELL / "Theme.qml", kit, "Theme.qml")
    for rel in SYSTEM_SCREENS:
        check_file_colours(ROOT / rel, kit, rel)

    theme = (SHELL / "Theme.qml").read_text(encoding="utf-8")
    corners = {int(v) for v in re.findall(r"property int radius\w*: (\d+)", theme)}
    if corners - KIT_CORNERS:
        fail(f"Theme.qml corners outside the kit: {sorted(corners - KIT_CORNERS)}")
    else:
        ok("Theme.qml corners are the kit's")

    weights = []
    springs = []
    for qml in sorted(SHELL.glob("*.qml")):
        if qml.name == "Theme.qml":
            continue
        text = qml.read_text(encoding="utf-8")
        bad = sorted({h for h in hex_colours(text) if h not in kit or green_or_yellow(h)})
        if bad:
            fail(f"{qml.name}: colours outside the kit: {', '.join('#' + h for h in bad)}")
        if re.search(r"Font\.(Thin|ExtraLight|Light|Normal|Medium|DemiBold|Bold|ExtraBold|Black)\b", text):
            weights.append(qml.name)
        if "Easing.OutBack" in text:
            springs.append(qml.name)
    if weights:
        fail("Font.* weights instead of Theme.weight*: " + ", ".join(weights))
    else:
        ok("shell QML weights come from Theme")
    if springs:
        fail("overshooting springs (Easing.OutBack): " + ", ".join(springs))
    else:
        ok("no overshooting springs")

    lua = (ROOT / "desktop/hypr/robinos.lua").read_text(encoding="utf-8")
    blurred = [m.group(1) for m in re.finditer(
        r"hl\.layer_rule\(\{[^}]*?namespace = \"([^\"]*robinos[^\"]*)\"[^}]*?\}[^}]*?blur\s*=\s*true", lua, re.S)]
    if blurred:
        fail("Hyprland blurs shell surfaces: " + ", ".join(blurred))
    else:
        ok("no blur on shell surfaces")

    lock = (ROOT / "desktop/hypr/hyprlock.conf").read_text(encoding="utf-8")
    if re.search(r"^\s*blur_passes\s*=\s*[1-9]", lock, re.M) or re.search(r"^\s*path\s*=\s*screenshot", lock, re.M):
        fail("hyprlock.conf blurs the screen behind the lock (the kit has no glass)")
    else:
        ok("no blur on the lock screen")

    if failures:
        print(f"robin-ui kit check failed: {len(failures)} problem(s).")
        return 1
    print("robin-ui kit check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
