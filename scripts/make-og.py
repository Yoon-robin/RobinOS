#!/usr/bin/env python3
"""Makes site/assets/og.jpg, the picture links to the landing page show, from
scripts/og-image.html with headless Chrome (1200x630) and Pillow.

    python scripts/make-og.py [path to chrome]
"""

import pathlib
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
]


def main():
    chrome = sys.argv[1] if len(sys.argv) > 1 else next((c for c in CANDIDATES if pathlib.Path(c).exists()), None)
    if not chrome:
        sys.exit("make-og: no Chrome found; pass its path")
    page = (ROOT / "scripts" / "og-image.html").as_uri()
    with tempfile.TemporaryDirectory() as tmp:
        shot = pathlib.Path(tmp) / "og.png"
        subprocess.run([chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                        f"--user-data-dir={tmp}/profile", "--window-size=1200,630", "--virtual-time-budget=5000",
                        f"--screenshot={shot}", page], check=True, capture_output=True)
        out = ROOT / "site" / "assets" / "og.jpg"
        Image.open(shot).convert("RGB").crop((0, 0, 1200, 630)).save(out, quality=88, optimize=True, progressive=True)
        print(f"{out.relative_to(ROOT)}: {out.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
