#!/usr/bin/env python3
"""Draws the RobinOS robin (assets/brand/robinos-mark.svg without its square) as
terminal art for fastfetch (desktop/fastfetch/robinos-logo.ansi): half-block
characters, two pixels per cell. White parts use the terminal's own foreground
color, so the robin stays visible in light mode; grey and Robin red are fixed.

    python3 assets/brand/build-terminal-logo.py desktop/fastfetch/robinos-logo.ansi   (needs rsvg-convert)
"""
import os
import re
import struct
import subprocess
import sys
import tempfile
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
WIDTH = 32  # pixels = terminal columns
SCALE = 8  # rendered this many times larger; each pixel takes its block's most common color
PALETTE = {  # name -> RGB of the mark's colors
    "fg": (250, 250, 250), "wing": (228, 228, 231), "grey": (161, 161, 170),
    "red": (229, 72, 77), "eye": (9, 9, 11),
}
FIXED = {"grey": (161, 161, 170), "red": (229, 72, 77)}


def robin_svg():
    """The mark without its rounded square, cropped to the robin and the prompt."""
    svg = open(os.path.join(HERE, "robinos-mark.svg"), encoding="utf-8").read()
    svg = re.sub(r'<rect width="256" height="256" rx="56"[^>]*/>', "", svg, count=1)
    return svg.replace('viewBox="0 0 256 256"', 'viewBox="38 48 184 168"', 1)


def read_png(data):
    pos, idat, w, h = 8, b"", 0, 0
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind, body = data[pos + 4:pos + 8], data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            w, h = struct.unpack(">II", body[:8])
        elif kind == b"IDAT":
            idat += body
    raw, stride, rows, prev, i = zlib.decompress(idat), w * 4, [], bytearray(w * 4), 0
    for _ in range(h):
        ft, line = raw[i], bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            a = line[x - 4] if x >= 4 else 0
            b, c = prev[x], (prev[x - 4] if x >= 4 else 0)
            if ft == 1:
                line[x] = (line[x] + a) & 255
            elif ft == 2:
                line[x] = (line[x] + b) & 255
            elif ft == 3:
                line[x] = (line[x] + ((a + b) >> 1)) & 255
            elif ft == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append([tuple(line[x:x + 4]) for x in range(0, stride, 4)])
        prev = line
    return w, h, rows


def classify(rgba):
    r, g, b, a = rgba
    if a < 128:
        return None
    name = min(PALETTE, key=lambda n: sum((u - v) ** 2 for u, v in zip(PALETTE[n], (r, g, b))))
    if name == "eye":
        return None  # the terminal background shows through, like the mark's dark eye
    return "fg" if name == "wing" else name


def downsample(rows, w, h):
    """Majority vote per SCALE x SCALE block, so anti-aliased edges don't turn grey."""
    out = []
    for by in range(h // SCALE):
        line = []
        for bx in range(w // SCALE):
            votes = {}
            for y in range(by * SCALE, (by + 1) * SCALE):
                for x in range(bx * SCALE, (bx + 1) * SCALE):
                    c = classify(rows[y][x])
                    votes[c] = votes.get(c, 0) + 1
            line.append(max(votes, key=votes.get))
        out.append(line)
    return out


def fg(color):
    return "\x1b[39m" if color == "fg" else "\x1b[38;2;%d;%d;%dm" % FIXED[color]


def bg(color):
    # Default foreground as a background isn't expressible, so a cell with white on
    # the bottom and a color on top flips to the lower half block instead
    return "\x1b[48;2;%d;%d;%dm" % FIXED[color]


def main(out):
    with tempfile.TemporaryDirectory() as tmp:
        src = os.path.join(tmp, "robin.svg")
        open(src, "w", encoding="utf-8").write(robin_svg())
        png = subprocess.run(["rsvg-convert", "-w", str(WIDTH * SCALE), src], capture_output=True, check=True).stdout
    w, h, rows = read_png(png)
    pixels = downsample(rows, w, h)
    w = len(pixels[0])
    if len(pixels) % 2:
        pixels.append([None] * w)
    lines = []
    for y in range(0, len(pixels), 2):
        cells = []
        for x in range(w):
            top, bottom = pixels[y][x], pixels[y + 1][x]
            if top is None and bottom is None:
                cells.append("\x1b[0m ")
            elif bottom is None:
                cells.append("\x1b[0m" + fg(top) + "▀")
            elif top is None:
                cells.append("\x1b[0m" + fg(bottom) + "▄")
            elif top == bottom:
                cells.append("\x1b[0m" + fg(top) + "█")
            elif top == "fg":
                cells.append("\x1b[0m" + fg("fg") + bg(bottom) + "▀")
            else:
                cells.append("\x1b[0m" + fg(bottom) + bg(top) + "▄")
        lines.append("".join(cells).rstrip() + "\x1b[0m")
    while lines and lines[-1].replace("\x1b[0m", "").strip() == "":
        lines.pop()
    open(out, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
    width = max(len(re.sub(r"\x1b\[[0-9;]*m", "", line)) for line in lines)
    print(f'{out}: "width": {width}, "height": {len(lines)} (desktop/fastfetch/config.jsonc)')


if __name__ == "__main__":
    main(sys.argv[1])
