#!/usr/bin/env python3
"""Checks and builds the generated parts of the landing page (site/).

1. The command pairs on the page (`data-win` → `data-linux` in site/index.html)
   must match the Windows command hints in desktop/bash/robinos-hints.sh, so the
   page shows exactly what the RobinOS terminal answers.
2. site/assets/fonts/Pretendard-Variable.woff2: the variable Pretendard cut down to
   the characters the page uses (fontTools), so the weights 450/550/650 are
   real and the page loads tens of KB instead of megabytes. The source is
   PretendardVariable.ttf from the checksum-verified release zip that
   scripts/fetch-fonts.sh caches (Pretendard 1.3.9, SIL OFL 1.1).

Run after changing the page's text or the hints:

    python scripts/build-site.py --fonts <folder with PretendardVariable.ttf>
"""

import argparse
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SITE = ROOT / "site"
HINTS = ROOT / "desktop" / "bash" / "robinos-hints.sh"


def function_body(text, name):
    start = text.index(name + "() {")
    end = text.index("\n}\n", start)
    return text[start:end]


def parse_hints():
    """Windows command -> Linux command, from __robinos_windows_hint."""
    text = HINTS.read_text(encoding="utf-8")
    hints = {}
    # `    ipconfig)            printf '%s' 'ip a|IP 주소와 ...' ;;` (or "..." quotes)
    line_re = re.compile(r"^\s+([a-z0-9.|+]+)\)\s+printf '%s' (['\"])(.*?)\2 ;;$")
    for line in function_body(text, "__robinos_windows_hint").splitlines():
        m = line_re.match(line)
        if not m:
            continue
        linux = m.group(3).partition("|")[0]
        for name in m.group(1).split("|"):
            hints[name] = linux
    if len(hints) < 40:
        sys.exit(f"build-site: only {len(hints)} hints parsed from {HINTS}, the format changed")
    return hints


def check_pairs(hints):
    html = (SITE / "index.html").read_text(encoding="utf-8")
    pair_re = re.compile(r'data-win="([^"]+)">([^<]+)</span>.*?data-linux="([^"]+)">([^<]+)</span>', re.S)
    pairs = [pair_re.search(li) for li in re.findall(r"<li[^>]*>.*?</li>", html, re.S)]
    pairs = [m for m in pairs if m]
    if not pairs:
        sys.exit("build-site: no data-win/data-linux pairs found in site/index.html")
    bad = []
    for m in pairs:
        win, win_text, linux, linux_text = m.groups()
        if win != win_text or linux != linux_text:
            bad.append(f"{win}: the shown text differs from the data attributes")
        elif hints.get(win) != linux:
            bad.append(f"{win} → {linux} on the page, but robinos-hints.sh says {hints.get(win)!r}")
    if bad:
        sys.exit("build-site: " + "; ".join(bad))
    print(f"site/index.html: {len(pairs)} command pairs match robinos-hints.sh")


def page_text():
    """Every character the page can show: the HTML, the script, the 404 page."""
    return "".join((SITE / name).read_text(encoding="utf-8")
                   for name in ("index.html", "main.js", "404.html"))


def subset_fonts(source, text):
    from fontTools import subset

    out = SITE / "assets" / "fonts"
    # Hangul and the punctuation around it, and printable ASCII: Pretendard is
    # the page's only typeface (robin-ui V5)
    chars = sorted({c for c in text if ord(c) > 0x7F}) + [chr(c) for c in range(0x20, 0x7F)]
    src = pathlib.Path(source) / "PretendardVariable.ttf"
    if not src.is_file():
        sys.exit(f"build-site: {src} is missing (see scripts/fetch-fonts.sh)")
    options = subset.Options()
    options.flavor = "woff2"
    options.layout_features = ["*"]
    font = subset.load_font(str(src), options)
    sub = subset.Subsetter(options)
    sub.populate(text="".join(chars))
    sub.subset(font)
    dest = out / "Pretendard-Variable.woff2"
    subset.save_font(font, str(dest), options)
    print(f"{dest.relative_to(ROOT)}: {dest.stat().st_size // 1024} KB")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--fonts", help="folder with Pretendard-<weight>.subset.woff2")
    args = parser.parse_args()

    check_pairs(parse_hints())
    if args.fonts:
        subset_fonts(args.fonts, page_text())


if __name__ == "__main__":
    main()
