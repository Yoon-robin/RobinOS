#!/usr/bin/env python3
"""Builds the RobinOS logo SVGs (docs/brand.md). The mark is the robin-ui V5 kit's
mark (.rk-mark): a near-black tile with rounded corners, a white robin on it and a
glow of the one blue around the robin, the same as the shell's Mark.qml. The name
is Pretendard 650 turned into paths, so the logo looks the same without the fonts
installed. Colours are the kit's (assets/brand/robin-ui/tokens.json); screens and
logos carry the name only, no tagline (docs/brand.md, 2026-11-24).

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


# the side column (page behind the logo), the mark's tile, the head white, the one blue
BG, TILE, WHITE, ACCENT = "#0A0E11", "#060A14", "#FFFFFF", "#4B7DFE"
# the kit's mark: radius 7 on a 30 tile, the glyph about three quarters of the tile
RADIUS, GLYPH = 7 / 30, 0.74


def robin(cid):
    """The robin as one white silhouette on the 256 grid (x 20-238, y 54-202): two
    circles, beak and tail, with the eye cut out so the tile shows through."""
    return f"""<mask id="{cid}-eye">
      <rect width="256" height="256" fill="#FFFFFF"/>
      <circle cx="178" cy="88" r="10" fill="#000000"/>
    </mask>
    <g fill="{WHITE}" mask="url(#{cid}-eye)">
      <circle cx="122" cy="138" r="64"/>
      <circle cx="168" cy="92" r="38"/>
      <path d="M200 76 L238 92 L200 106 Z"/>
      <path d="M78 164 L26 190 C20 193 22 202 29 201 L96 186 Z"/>
    </g>"""


def tile(cid):
    """The mark on the 256 grid: the kit's tile, the robin and its blue glow
    (text-shadow 0 0 10px rgb(75 125 254 / 90%) on a 30 tile, scaled up and kept
    inside the tile)."""
    r = round(256 * RADIUS)
    off = 256 * (1 - GLYPH) / 2
    return f"""<defs>
    <clipPath id="{cid}-tile"><rect width="256" height="256" rx="{r}"/></clipPath>
    <filter id="{cid}-glow" x="-40%" y="-40%" width="180%" height="180%" color-interpolation-filters="sRGB">
      <feGaussianBlur in="SourceAlpha" stdDeviation="22" result="wide"/>
      <feGaussianBlur in="SourceAlpha" stdDeviation="7" result="near"/>
      <feMerge result="blur"><feMergeNode in="wide"/><feMergeNode in="near"/></feMerge>
      <feFlood flood-color="{ACCENT}" flood-opacity="0.9"/>
      <feComposite operator="in" in2="blur" result="glow"/>
      <feMerge><feMergeNode in="glow"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>
  <rect width="256" height="256" rx="{r}" fill="{TILE}"/>
  <g clip-path="url(#{cid}-tile)">
    <g filter="url(#{cid}-glow)">
      <g transform="translate({off:.2f} {off:.2f}) scale({GLYPH})">
    {robin(cid)}
      </g>
    </g>
  </g>"""


def mark():
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" role="img" aria-labelledby="title desc">
  <title id="title">RobinOS</title>
  <desc id="desc">RobinOS 마크: 거의 검은 네모 위의 하얀 울새와 파란 번짐</desc>
  {tile("robinos-mark")}
</svg>
"""


def glyph():
    """One-colour robin for tiny sizes (the shell's Mark.qml, the login screen),
    which put it on the tile and add the glow themselves."""
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
    size, pad = 116, 32
    word, ww = text_path(PRETENDARD, 650, "RobinOS", 68, pad + size + 30, 114, tracking=-0.02)
    width = int(pad + size + 30 + ww + 40)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} 180" role="img" aria-labelledby="title desc">
  <title id="title">RobinOS</title>
  <desc id="desc">RobinOS 가로형 로고: 울새 마크와 이름</desc>
  <rect width="{width}" height="180" rx="14" fill="{BG}"/>
  <g transform="translate({pad} {(180 - size) / 2:.1f}) scale({size / 256})">
  {tile("robinos-horizontal")}
  </g>
  <path d="{word}" fill="{WHITE}"/>
</svg>
"""


def lockup():
    word, ww = text_path(PRETENDARD, 650, "RobinOS", 74, 0, 0, tracking=-0.02)
    width, size = 560, 208
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} 400" role="img" aria-labelledby="title desc">
  <title id="title">RobinOS</title>
  <desc id="desc">RobinOS 로고: 울새 마크와 이름</desc>
  <rect width="{width}" height="400" rx="14" fill="{BG}"/>
  <g transform="translate({(width - size) / 2:.1f} 40) scale({size / 256})">
  {tile("robinos-logo")}
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
    mark_size, gap = 64, 16
    width = mark_size + gap + ww
    x0 = (640 - width) / 2
    tx = x0 + mark_size + gap
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 480" width="640" height="480">
  <rect width="640" height="480" fill="{BG}"/>
  <g transform="translate({x0:.1f} 40) scale({mark_size / 256})">
  {tile("robinos-splash")}
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
        open(f"{out}/{name}", "w", encoding="utf-8", newline="\n").write(svg)
        print(name, len(svg))
