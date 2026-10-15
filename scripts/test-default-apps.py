#!/usr/bin/env python3
"""Checks desktop/bin/robinos-default-apps with a made-up set of apps and a stand-in
xdg-mime (a text file instead of ~/.config/mimeapps.list)."""

import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOL = os.path.join(ROOT, "desktop", "bin", "robinos-default-apps")

failed = False


def check(name, ok, detail=""):
    global failed
    print(("  ok      " if ok else "  FAILED  ") + name + ("" if ok or not detail else ": " + detail))
    if not ok:
        failed = True


def write(path, text, mode=None):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    if mode:
        os.chmod(path, mode)


def desktop(name, mimes, extra=""):
    return f"[Desktop Entry]\nType=Application\nName={name}\nExec=x\nMimeType={mimes}\n{extra}"


with tempfile.TemporaryDirectory() as tmp:
    share = os.path.join(tmp, "usr/share")
    home_share = os.path.join(tmp, "home/.local/share")
    state = os.path.join(tmp, "mimeapps")
    web = "text/html;x-scheme-handler/http;x-scheme-handler/https;"

    write(share + "/applications/firefox.desktop", desktop("Firefox", web))
    write(share + "/applications/chromium.desktop", desktop("Chromium", web) + "Name[ko]=크로미움\n")
    write(share + "/applications/hidden-browser.desktop", desktop("Hidden", web, "NoDisplay=true\n"))
    write(share + "/applications/org.gnome.TextEditor.desktop", desktop("텍스트 편집기", "text/plain;"))
    write(share + "/applications/nvim.desktop", desktop("Neovim", "text/plain;", "Terminal=true\n"))
    write(share + "/applications/org.gnome.Loupe.desktop", desktop("이미지 보기", "image/png;image/jpeg;"))
    write(share + "/applications/kde5/viewer.desktop", desktop("Viewer", "image/png;"))
    write(share + "/applications/not-an-app.desktop", "[Desktop Entry]\nType=Link\nName=Link\nMimeType=application/pdf;\n")
    # The same id in the user's own folder: the first folder wins
    write(home_share + "/applications/firefox.desktop", desktop("Firefox (mine)", web))

    bin_dir = os.path.join(tmp, "bin")
    write(bin_dir + "/xdg-mime", f"""#!/bin/sh
case "$1" in
  query) grep "^$3=" '{state}' 2>/dev/null | tail -n 1 | cut -d= -f2- ;;
  default) app="$2"; shift 2; for m in "$@"; do printf '%s=%s\\n' "$m" "$app" >> '{state}'; done ;;
esac
""", 0o755)
    write(state, "x-scheme-handler/https=firefox.desktop\nimage/png=org.gnome.Loupe.desktop\n")

    env = dict(os.environ, XDG_DATA_HOME=home_share, XDG_DATA_DIRS=share,
               PATH=bin_dir + os.pathsep + os.environ["PATH"], HOME=os.path.join(tmp, "home"), PYTHONUTF8="1")

    def run(*args):
        return subprocess.run([sys.executable, TOOL, *args], capture_output=True, text=True, env=env, encoding="utf-8")

    listed = run("list")
    check("list works", listed.returncode == 0, listed.stderr)
    kinds = {k["key"]: k for k in json.loads(listed.stdout)}
    check("seven kinds", list(kinds) == ["browser", "mail", "photos", "video", "music", "pdf", "text"], str(list(kinds)))

    browser = kinds["browser"]
    check("the current browser comes from xdg-mime", browser["current"] == "firefox.desktop")
    check("the current app's name is the first folder's", browser["currentName"] == "Firefox (mine)", browser["currentName"])
    ids = [a["id"] for a in browser["apps"]]
    check("browsers sorted by name, hidden ones left out", ids == ["firefox.desktop", "chromium.desktop"], str(ids))
    check("a Korean name is used", [a["name"] for a in browser["apps"]][1] == "크로미움")
    check("a kind nobody handles has no apps", kinds["mail"]["apps"] == [] and kinds["mail"]["current"] == "")
    check("an app that only runs in a terminal isn't offered",
          [a["id"] for a in kinds["text"]["apps"]] == ["org.gnome.TextEditor.desktop"])
    check("a subfolder's id has a dash", "kde5-viewer.desktop" in [a["id"] for a in kinds["photos"]["apps"]])
    check("a .desktop that isn't an Application isn't offered", kinds["pdf"]["apps"] == [])

    done = run("set", "browser", "chromium.desktop")
    check("setting a browser works", done.returncode == 0, done.stderr)
    with open(state, encoding="utf-8") as f:
        lines = f.read().splitlines()
    check("all of its types are set",
          all(f"{m}=chromium.desktop" in lines for m in ["x-scheme-handler/https", "x-scheme-handler/http", "text/html"]), str(lines))
    again = {k["key"]: k for k in json.loads(run("list").stdout)}
    check("the list shows the new default", again["browser"]["current"] == "chromium.desktop" and again["browser"]["currentName"] == "크로미움")

    before = len(lines)
    refused = run("set", "browser", "org.gnome.Loupe.desktop")
    check("an app that can't open it is refused", refused.returncode == 1)
    check("nothing was written for it", len(open(state, encoding="utf-8").read().splitlines()) == before)
    check("an unknown kind is refused", run("set", "games", "firefox.desktop").returncode == 2)
    check("a missing argument prints the usage", run("set", "browser").returncode == 2)
    check("a bad id with a path isn't accepted", run("set", "browser", "../../x.desktop").returncode == 1)

    # An image viewer that says it opens PNG and JPEG doesn't get GIF, WebP or HEIF
    done = run("set", "photos", "org.gnome.Loupe.desktop")
    check("setting a photo app works", done.returncode == 0, done.stderr)
    lines = open(state, encoding="utf-8").read().splitlines()
    loupe = sorted(line.split("=")[0] for line in lines if line.endswith("=org.gnome.Loupe.desktop"))
    check("only the formats the app opens are set", "image/gif" not in loupe and "image/jpeg" in loupe, str(loupe))

    # Hidden=true in the user's folder hides the system's copy of the same app
    write(home_share + "/applications/chromium.desktop", desktop("Chromium", web, "Hidden=true\n"))
    ids = [a["id"] for a in {k["key"]: k for k in json.loads(run("list").stdout)}["browser"]["apps"]]
    check("a Hidden=true copy in the user's folder hides the app", "chromium.desktop" not in ids, str(ids))

    # Without xdg-mime: a message, not a Python traceback
    # (not the Python folder: on Arch that is /usr/bin, where the real xdg-mime lives)
    empty = os.path.join(tmp, "empty-bin")
    os.makedirs(empty)
    no_tool = dict(env, PATH=empty)
    gone = subprocess.run([sys.executable, TOOL, "set", "browser", "firefox.desktop"], capture_output=True, text=True,
                          env=no_tool, encoding="utf-8")
    check("without xdg-mime it says so", gone.returncode == 1 and "Traceback" not in gone.stderr, gone.stderr)

sys.exit(1 if failed else 0)
