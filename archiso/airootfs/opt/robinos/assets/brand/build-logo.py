#!/usr/bin/env python3
"""Builds the RobinOS logo SVGs (docs/brand.md): a white robin sitting on a terminal
prompt's cursor. The name is Pretendard turned into paths, so the logo looks the
same without the fonts installed. Colours are the robin-ui V5 kit's
(assets/brand/robin-ui/tokens.json); screens and logos carry the name only, no
tagline (docs/brand.md, 2026-11-24).

    scripts/fetch-fonts.sh /tmp/robinfonts
    python3 assets/brand/build-logo.py /tmp/robinfonts assets/brand    (needs python-fonttools)
"""
import sys

from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

_cache = {}


def font(path, wght):
    key = (path, wght)
    if key not in _cache:
        f = TTFont(path)
        if "fvar" in f:
            f = instantiateVariableFont(f, {"wght": wght})
        _cache[key] = f
    return _cache[key]


def text_path(path, wght, text, size, x, y, tracking=0.0):
    """Returns (svg path d, width) for text whose baseline starts at (x, y)."""
    f = font(path, wght)
    upem = f["head"].unitsPerEm
    scale = size / upem
    cmap = f.getBestCmap()
    glyphs = f.getGlyphSet()
    hmtx = f["hmtx"]
    pen = SVGPathPen(glyphs)
    cursor = 0.0
    for ch in text:
        name = cmap.get(ord(ch))
        if name is None:
            continue
        tpen = TransformPen(pen, (scale, 0, 0, -scale, x + cursor, y))
        glyphs[name].draw(tpen)
        cursor += hmtx[name][0] * scale + tracking * size
    return pen.getCommands(), cursor - tracking * size



# side, head, text, soft and the one blue; CARD is the kit's card face
BG, WHITE, WING, GREY, ACCENT = "#0A0E11", "#F0F0F0", "#E6E7E9", "#8A8E94", "#4B7DFE"
CARD = "#0F1115"


def robin(cid):
    """The robin and the prompt on the 256 grid (content roughly x 44-218, y 58-214)."""
    return f"""<defs>
    <clipPath id="{cid}">
      <circle cx="124" cy="130" r="54"/>
      <circle cx="164" cy="92" r="32"/>
    </clipPath>
  </defs>
  <path d="M82 150 L50 165 C45 167.5 46.5 174 52 173.5 L96 166 Z" fill="{GREY}"/>
  <g clip-path="url(#{cid})">
    <rect width="256" height="256" fill="{WHITE}"/>
    <path d="M66 110 C 92 100, 122 112, 132 140 C 106 148, 82 140, 66 124 Z" fill="{WING}"/>
  </g>
  <path d="M193 84 L218 93 L193 102 Z" fill="{GREY}"/>
  <circle cx="174" cy="85" r="6.5" fill="{BG}"/>
  <path d="M114 184 V203 M134 184 V203" stroke="{GREY}" stroke-width="6" stroke-linecap="round"/>
  <path d="M48 193 L65 205 L48 217" fill="none" stroke="{ACCENT}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="84" y="200" width="96" height="10" rx="5" fill="{WHITE}"/>"""


def mark():
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" role="img" aria-labelledby="title desc">
  <title id="title">RobinOS</title>
  <desc id="desc">RobinOS 마크: 터미널 프롬프트의 커서 위에 앉은 울새</desc>
  <rect width="256" height="256" rx="56" fill="{BG}"/>
  <g transform="translate(-3 -7)">
  {robin("robinos-mark-bird")}
  </g>
</svg>
"""


def glyph():
    """One-colour robin for tiny sizes (the shell's bar, the login screen): white on
    the accent colour, with the eye cut out so the accent shows through."""
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" role="img" aria-label="RobinOS">
  <defs>
    <mask id="robinos-glyph-eye">
      <rect width="256" height="256" fill="#FFFFFF"/>
      <circle cx="178" cy="88" r="10" fill="#000000"/>
    </mask>
  </defs>
  <g fill="#FFFFFF" mask="url(#robinos-glyph-eye)">
    <circle cx="122" cy="138" r="64"/>
    <circle cx="168" cy="92" r="38"/>
    <path d="M200 76 L238 92 L200 106 Z"/>
    <path d="M78 164 L26 190 C20 193 22 202 29 201 L96 186 Z"/>
  </g>
</svg>
"""


def horizontal():
    word, ww = text_path(PRETENDARD, 650, "RobinOS", 68, 196, 114, tracking=-0.02)
    width = int(196 + ww + 48)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} 180" role="img" aria-labelledby="title desc">
  <title id="title">RobinOS</title>
  <desc id="desc">RobinOS 가로형 로고: 프롬프트 커서 위의 울새와 이름</desc>
  <rect width="{width}" height="180" rx="14" fill="{BG}"/>
  <g transform="translate(4 -16) scale(0.78)">
  {robin("robinos-horizontal-bird")}
  </g>
  <path d="{word}" fill="{WHITE}"/>
</svg>
"""


def lockup():
    word, ww = text_path(PRETENDARD, 650, "RobinOS", 74, 0, 0, tracking=-0.02)
    width = 560
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} 400" role="img" aria-labelledby="title desc">
  <title id="title">RobinOS</title>
  <desc id="desc">RobinOS 로고: 울새 마크와 이름</desc>
  <rect width="{width}" height="400" rx="14" fill="{BG}"/>
  <g transform="translate({width / 2 - 108} 30) scale(0.84)">
    <rect width="256" height="256" rx="56" fill="{CARD}"/>
    <g transform="translate(-3 -7)">
    {robin("robinos-logo-bird")}
    </g>
  </g>
  <g transform="translate({(width - ww) / 2:.1f} 346)"><path d="{word}" fill="{WHITE}"/></g>
</svg>
"""


def boot_splash():
    """Background of the live ISO's BIOS boot menu (syslinux vesamenu, 640x480).
    The mark and the name sit above the menu box, which syslinux draws from row 10
    (y 160) down; the bottom rows hold syslinux's help text, so they stay empty.
    Screens carry the name only, no tagline (docs/brand.md).
    PNG: rsvg-convert -w 640 -h 480 robinos-boot-splash.svg -o themes/syslinux/splash.png"""
    word, ww = text_path(PRETENDARD, 650, "RobinOS", 38, 0, 0, tracking=-0.02)
    mark_size, gap = 64, 14
    width = mark_size + gap + ww
    x0 = (640 - width) / 2
    tx = x0 + mark_size + gap
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 480" width="640" height="480">
  <defs>
    <radialGradient id="robinos-splash-glow" cx="320" cy="60" r="300" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="{ACCENT}" stop-opacity="0.14"/>
      <stop offset="1" stop-color="{ACCENT}" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="640" height="480" fill="{BG}"/>
  <rect width="640" height="480" fill="url(#robinos-splash-glow)"/>
  <g transform="translate({x0:.1f} 40) scale({mark_size / 256})">
    <rect width="256" height="256" rx="56" fill="{CARD}"/>
    <g transform="translate(-3 -7)">
    {robin("robinos-splash-bird")}
    </g>
  </g>
  <g transform="translate({tx:.1f} 86)"><path d="{word}" fill="{WHITE}"/></g>
</svg>
"""


if __name__ == "__main__":
    fonts, out = sys.argv[1], sys.argv[2]
    PRETENDARD = f"{fonts}/PretendardVariable.ttf"
    for name, svg in (("robinos-mark.svg", mark()), ("robinos-logo-horizontal.svg", horizontal()),
                      ("robinos-logo.svg", lockup()), ("robinos-glyph.svg", glyph()),
                      ("robinos-boot-splash.svg", boot_splash())):
        open(f"{out}/{name}", "w", encoding="utf-8").write(svg)
        print(name, len(svg))
