#!/usr/bin/env python3
"""Builds the generated parts of the landing page (site/).

1. site/hints.json: the Windows command hints from desktop/bash/robinos-hints.sh,
   so the page's terminal answers exactly like the RobinOS terminal does.
2. site/assets/fonts/Pretendard-*.woff2: Pretendard cut down to the characters the
   page uses (fontTools), so the page loads a few dozen KB instead of a megabyte.
   The full subset fonts come from the checksum-verified font cache that
   scripts/fetch-fonts.sh fills (Pretendard 1.3.9, SIL OFL 1.1).

Run after changing the page's text or the hints:

    python scripts/build-site.py --fonts <folder with Pretendard-*.subset.woff2>
"""

import argparse
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SITE = ROOT / "site"
HINTS = ROOT / "desktop" / "bash" / "robinos-hints.sh"
WEIGHTS = ["Regular", "SemiBold", "Bold"]


def function_body(text, name):
    start = text.index(name + "() {")
    end = text.index("\n}\n", start)
    return text[start:end]


def parse_hints():
    text = HINTS.read_text(encoding="utf-8")
    hints = {}
    # `    ipconfig)            printf '%s' 'ip a|IP 주소와 ...' ;;` (or "..." quotes)
    line_re = re.compile(r"^\s+([a-z0-9.|+]+)\)\s+printf '%s' (['\"])(.*?)\2 ;;$")
    for line in function_body(text, "__robinos_windows_hint").splitlines():
        m = line_re.match(line)
        if not m:
            continue
        linux, _, what = m.group(3).partition("|")
        for name in m.group(1).split("|"):
            hints[name] = {"linux": linux, "what": what}
    mission_re = re.compile(r"^\s+([a-z0-9.|+]+)\)\s+printf '(\d+)' ;;$")
    for line in function_body(text, "__robinos_hint_mission").splitlines():
        m = mission_re.match(line)
        if not m:
            continue
        for name in m.group(1).split("|"):
            if name in hints:
                hints[name]["mission"] = int(m.group(2))
    if len(hints) < 40:
        sys.exit(f"build-site: only {len(hints)} hints parsed from {HINTS}, the format changed")
    return hints


def page_text(hints):
    """Every character the page can show: the HTML, the script's strings, the hints."""
    parts = [(SITE / "index.html").read_text(encoding="utf-8"),
             (SITE / "main.js").read_text(encoding="utf-8"),
             (SITE / "404.html").read_text(encoding="utf-8")]
    for name, hint in hints.items():
        parts += [name, hint["linux"], hint["what"]]
    return "".join(parts)


def subset_fonts(source, text):
    from fontTools import subset

    out = SITE / "assets" / "fonts"
    # Hangul and the punctuation around it; Latin comes from Geist
    chars = sorted({c for c in text if ord(c) > 0x7F}) + [chr(c) for c in range(0x20, 0x7F)]
    for weight in WEIGHTS:
        src = pathlib.Path(source) / f"Pretendard-{weight}.subset.woff2"
        if not src.is_file():
            sys.exit(f"build-site: {src} is missing (see scripts/fetch-fonts.sh)")
        options = subset.Options()
        options.flavor = "woff2"
        options.layout_features = ["*"]
        font = subset.load_font(str(src), options)
        sub = subset.Subsetter(options)
        sub.populate(text="".join(chars))
        sub.subset(font)
        dest = out / f"Pretendard-{weight}.woff2"
        subset.save_font(font, str(dest), options)
        print(f"{dest.relative_to(ROOT)}: {dest.stat().st_size // 1024} KB")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--fonts", help="folder with Pretendard-<weight>.subset.woff2")
    args = parser.parse_args()

    hints = parse_hints()
    out = SITE / "hints.json"
    out.write_text(json.dumps(hints, ensure_ascii=False, sort_keys=True, indent=0) + "\n", encoding="utf-8")
    print(f"{out.relative_to(ROOT)}: {len(hints)} commands, "
          f"{sum('mission' in h for h in hints.values())} with a mission")
    if args.fonts:
        subset_fonts(args.fonts, page_text(hints))


if __name__ == "__main__":
    main()
