#!/usr/bin/env python3
"""Builds the RobinOS logo SVGs (docs/brand.md): a white robin sitting on a terminal
prompt's cursor. The name and tagline are Geist and Pretendard turned into paths,
so the logo looks the same without the fonts installed.

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



BG, WHITE, WING, GREY, RED = "#09090B", "#FAFAFA", "#E4E4E7", "#A1A1AA", "#E5484D"
TAGLINE = "매일 쓰면서 배우는 보안 학습 OS"


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
  <path d="M48 193 L65 205 L48 217" fill="none" stroke="{RED}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>
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
    word, ww = text_path(GEIST, 700, "RobinOS", 66, 196, 104, tracking=-0.02)
    tag, tw = text_path(PRETENDARD, 500, TAGLINE, 22, 199, 142)
    width = int(max(196 + ww, 199 + tw) + 44)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} 180" role="img" aria-labelledby="title desc">
  <title id="title">RobinOS</title>
  <desc id="desc">RobinOS 가로형 로고: 프롬프트 커서 위의 울새와 "{TAGLINE}"</desc>
  <rect width="{width}" height="180" rx="28" fill="{BG}"/>
  <g transform="translate(4 -16) scale(0.78)">
  {robin("robinos-horizontal-bird")}
  </g>
  <path d="{word}" fill="{WHITE}"/>
  <path d="{tag}" fill="{GREY}"/>
</svg>
"""


def lockup():
    word, ww = text_path(GEIST, 700, "RobinOS", 72, 0, 0, tracking=-0.02)
    tag, tw = text_path(PRETENDARD, 500, TAGLINE, 24, 0, 0)
    width = 560
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} 460" role="img" aria-labelledby="title desc">
  <title id="title">RobinOS</title>
  <desc id="desc">RobinOS 로고: 울새 마크, 이름, "{TAGLINE}"</desc>
  <rect width="{width}" height="460" rx="36" fill="{BG}"/>
  <g transform="translate({width / 2 - 108} 30) scale(0.84)">
    <rect width="256" height="256" rx="56" fill="#18181B"/>
    <g transform="translate(-3 -7)">
    {robin("robinos-logo-bird")}
    </g>
  </g>
  <g transform="translate({(width - ww) / 2:.1f} 340)"><path d="{word}" fill="{WHITE}"/></g>
  <g transform="translate({(width - tw) / 2:.1f} 392)"><path d="{tag}" fill="{GREY}"/></g>
</svg>
"""


if __name__ == "__main__":
    fonts, out = sys.argv[1], sys.argv[2]
    GEIST = f"{fonts}/Geist[wght].ttf"
    PRETENDARD = f"{fonts}/PretendardVariable.ttf"
    for name, svg in (("robinos-mark.svg", mark()), ("robinos-logo-horizontal.svg", horizontal()),
                      ("robinos-logo.svg", lockup()), ("robinos-glyph.svg", glyph())):
        open(f"{out}/{name}", "w", encoding="utf-8").write(svg)
        print(name, len(svg))
