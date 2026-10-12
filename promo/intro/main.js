// RobinOS intro video: one paused GSAP timeline.
//   preview: index.html          (click or Space = play/pause, ←/→ = 2 s, ?t=12 starts at 12 s)
//   render:  index.html?render   (render.mjs calls __video.seek(t) for every frame and captures it)
// Everything that changes by itself (typing, carets, window contents that follow
// a window's size) is computed from t in ambient(), never by CSS, so a frozen
// frame is always the same.
import { gsap } from "./node_modules/gsap/index.js";
import { CustomEase } from "./node_modules/gsap/CustomEase.js";
import { FPS, BEAT, TYPE, TYPE_FAST, DURATION, T, EV, WORKSPACES, TYPING, KEYS } from "./cues.js";

gsap.registerPlugin(CustomEase);

// RobinOS's own animation curves (desktop/hypr/robinos.lua)
CustomEase.create("quint", "0.23, 1, 0.32, 1");          // easeOutQuint: borders, layers, workspaces
CustomEase.create("almostLinear", "0.5, 0.5, 0.75, 1");  // fades
// hl.curve("easy"): spring, mass 1, stiffness 238.12, dampening 24.21 → ζ 0.78, a ~2% overshoot.
// Closed form of that spring over 0.5 s.
const SPRING_TIME = 0.5;
const spring = (() => {
  const w0 = Math.sqrt(238.1191), zeta = 24.21279333 / (2 * w0), wd = w0 * Math.sqrt(1 - zeta * zeta);
  const a = zeta * w0 * SPRING_TIME, b = wd * SPRING_TIME;
  return (p) => (p >= 1 ? 1 : 1 - Math.exp(-a * p) * (Math.cos(b * p) + (a / b) * Math.sin(b * p)));
})();

const params = new URLSearchParams(location.search);
const RENDER = params.has("render");
const q = (s, root = document) => root.querySelector(s);
const qa = (s, root = document) => [...root.querySelectorAll(s)];

// Stage geometry: the desktop is the real shell at 1.6x
const W = 1920, H = 1080, BAR = 58, STRIP = 128;
const AREA_H = H - BAR - STRIP;               // 894
const GAP_OUT = 16, GAP_IN = 13;               // gaps_out 10, 2 × gaps_in 4 (x1.6)

// ── the RobinOS mark in parts (assets/brand/robinos-mark.svg without its tile) ──
let markCount = 0;
function markSvg() {
  const id = `robin-clip-${++markCount}`;
  return `<svg viewBox="0 0 256 256" aria-hidden="true">
  <defs><clipPath id="${id}"><circle cx="124" cy="130" r="54"/><circle cx="164" cy="92" r="32"/></clipPath></defs>
  <g transform="translate(-3 -7)">
    <g class="m-robin">
      <path d="M82 150 L50 165 C45 167.5 46.5 174 52 173.5 L96 166 Z" fill="#A1A1AA"/>
      <g clip-path="url(#${id})"><rect width="256" height="256" fill="#FAFAFA"/><path d="M66 110 C 92 100, 122 112, 132 140 C 106 148, 82 140, 66 124 Z" fill="#E4E4E7"/></g>
      <path d="M193 84 L218 93 L193 102 Z" fill="#A1A1AA"/>
      <circle cx="174" cy="85" r="6.5" fill="#09090B"/>
      <path d="M114 184 V203 M134 184 V203" stroke="#A1A1AA" stroke-width="6" stroke-linecap="round"/>
    </g>
    <path class="m-chev" d="M48 193 L65 205 L48 217" fill="none" stroke="#E5484D" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>
    <rect class="m-cursor" x="84" y="200" width="96" height="10" rx="5" fill="#FAFAFA"/>
  </g>
</svg>`;
}
const GLYPH = '<svg viewBox="0 0 256 256"><g fill="#fff"><circle cx="122" cy="138" r="64"/><circle cx="168" cy="92" r="38"/><path d="M200 76 L238 92 L200 106 Z"/><path d="M78 164 L26 190 C20 193 22 202 29 201 L96 186 Z"/></g><circle cx="178" cy="88" r="10" fill="#E5484D"/></svg>';
const ICONS = {
  network: '<rect x="16" y="16" width="6" height="6" rx="1"/><rect x="2" y="16" width="6" height="6" rx="1"/><rect x="9" y="2" width="6" height="6" rx="1"/><path d="M5 16v-3a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v3"/><path d="M12 12V8"/>',
  volume: '<path d="M11 4.7a.7.7 0 0 0-1.2-.5L6.4 7.6A1.4 1.4 0 0 1 5.4 8H3a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h2.4a1.4 1.4 0 0 1 1 .4l3.4 3.4a.7.7 0 0 0 1.2-.5z"/><path d="M16 9a5 5 0 0 1 0 6"/>',
  bell: '<path d="M10.3 21a1.9 1.9 0 0 0 3.4 0"/><path d="M3.3 15.3A1 1 0 0 0 4 17h16a1 1 0 0 0 .7-1.7C19.4 14 18 12.5 18 8A6 6 0 0 0 6 8c0 4.5-1.4 6-2.7 7.3"/>',
};

function barHtml() {
  return `<div class="bar-left"><span class="logo-pill"><i class="logo-ico">${GLYPH}</i>RobinOS</span>
    <span class="wsnums"><i class="ws-pill"></i>${[1, 2, 3, 4, 5].map((n) => `<span data-n="${n}">${n}</span>`).join("")}</span>
    <span class="title"></span></div>
    <div class="bar-center">10월 12일 (월) 오전 9:41</div>
    <div class="bar-right"><span class="ime">A</span>${["network", "volume", "bell"].map((k) => `<svg viewBox="0 0 24 24">${ICONS[k]}</svg>`).join("")}</div>`;
}

// ── real screens, cropped from the 1600x900 test screenshots ──
function cropInfo(el) {
  const [x, y, w, h] = el.dataset.crop.split(",").map(Number);
  return { x, y, w, h, src: el.dataset.src };
}
function applyCrop(el, s) {
  const { x, y, w, h, src } = cropInfo(el);
  Object.assign(el.style, {
    width: `${w * s}px`, height: `${h * s}px`,
    backgroundImage: `url(assets/${src})`,
    backgroundSize: `${1600 * s}px ${900 * s}px`,
    backgroundPosition: `${-x * s}px ${-y * s}px`,
  });
  el._s = s;
}
function setupCrops() {
  for (const el of qa(".crop")) {
    const { w, h } = cropInfo(el), fit = el.dataset.fit;
    if (fit === "stage") {        // fills the screen above the prompt
      const s = Math.min(W / w, (H - STRIP) / h);
      applyCrop(el, s);
      Object.assign(el.style, { left: `${(W - w * s) / 2}px`, top: `${(H - STRIP - h * s) / 2}px` });
    } else if (fit === "cover") { // the whole stage
      const s = Math.max(W / w, H / h);
      applyCrop(el, s);
      Object.assign(el.style, { left: `${(W - w * s) / 2}px`, top: `${(H - h * s) / 2}px` });
    } else if (fit !== "win") {
      applyCrop(el, Number(el.dataset.scale || 1));
    }
  }
}
// A crop inside a window follows the window's size (contain, centered)
function fitWindowCrops() {
  for (const el of qa('.crop[data-fit="win"]')) {
    const win = el.parentElement, { w, h } = cropInfo(el);
    const ww = win.offsetWidth, wh = win.offsetHeight;
    if (!ww || !wh) continue;
    const s = Math.min((ww - 24) / w, (wh - 24) / h);
    if (el._s !== s) applyCrop(el, s);
    el.style.left = `${(ww - w * s) / 2}px`;
    el.style.top = `${(wh - h * s) / 2}px`;
  }
}
// Layers sit where the real shell puts them: centered in the work area, or under the bar on the right
function placeLayer(layer, where) {
  const crop = q(".crop", layer), w = crop.offsetWidth, h = crop.offsetHeight;
  Object.assign(layer.style, { width: `${w}px`, height: `${h}px` });
  if (where === "center") Object.assign(layer.style, { left: `${(W - w) / 2}px`, top: `${(AREA_H - h) / 2}px` });
  if (where === "right") Object.assign(layer.style, { left: `${W - GAP_OUT - w}px`, top: "10px" });
  if (where === "center-left") Object.assign(layer.style, { left: `${(W - w) / 2 - 120}px`, top: `${(AREA_H - h) / 2}px` });
}

// Hyprland's dwindle layout: each new window splits the last one along its longer side
function dwindle(n) {
  const rects = [{ x: GAP_OUT, y: GAP_OUT, w: W - 2 * GAP_OUT, h: AREA_H - 2 * GAP_OUT }];
  for (let i = 1; i < n; i++) {
    const r = rects[i - 1];
    if (r.w >= r.h) {
      const w = (r.w - GAP_IN) / 2;
      rects[i - 1] = { ...r, w };
      rects.push({ x: r.x + w + GAP_IN, y: r.y, w, h: r.h });
    } else {
      const h = (r.h - GAP_IN) / 2;
      rects[i - 1] = { ...r, h };
      rects.push({ x: r.x, y: r.y + h + GAP_IN, w: r.w, h });
    }
  }
  return rects;
}
const css = (r) => ({ left: r.x, top: r.y, width: r.w, height: r.h });

// ── motion vocabulary: RobinOS's own animations ──
const tl = gsap.timeline({ paused: true });

// Scenes (children of the stage) are shown with visibility. Anything inside a
// scene uses autoAlpha instead: a child set to visibility: visible would stay
// on screen after its scene is hidden.
function show(el, at) { tl.set(el, { visibility: "visible" }, at); }
function hide(el, at) { tl.set(el, { visibility: "hidden" }, at); }
function on(el, at) { tl.set(el, { autoAlpha: 1 }, at); }
function off(el, at) { tl.set(el, { autoAlpha: 0 }, at); }
// windowsIn: popin 92% with the "easy" spring, plus fadeIn (almostLinear)
function windowIn(win, at, rect) {
  gsap.set(win, { ...css(rect), autoAlpha: 0 });
  tl.fromTo(win, { scale: 0.92 }, { scale: 1, duration: SPRING_TIME, ease: spring, immediateRender: false }, at);
  tl.fromTo(win, { autoAlpha: 0 }, { autoAlpha: 1, duration: 0.17, ease: "almostLinear", immediateRender: false }, at);
  tl.to(win, { "--bd": 0.22, duration: 0.4, ease: "quint" }, at); // the new window is active
}
// windows: moving or resizing follows the same spring
function windowTo(win, at, rect) {
  tl.to(win, { ...css(rect), duration: SPRING_TIME, ease: spring }, at);
}
function inactive(win, at) { tl.to(win, { "--bd": 0.08, duration: 0.4, ease: "quint" }, at); }
// windowsOut: popin 92%, linear, 0.14 s
function windowOut(win, at) {
  tl.to(win, { scale: 0.92, autoAlpha: 0, duration: 0.14, ease: "none" }, at);
}
// layersIn: fade with easeOutQuint (launcher, panels); layersOut: linear and quick
function layerIn(layer, at) { tl.fromTo(layer, { autoAlpha: 0, scale: 0.985 }, { autoAlpha: 1, scale: 1, duration: 0.4, ease: "quint", immediateRender: false }, at); }
function layerOut(layer, at) { tl.to(layer, { autoAlpha: 0, duration: 0.15, ease: "none" }, at); }

// ── scenes ──
function build() {
  const logo = q("#logo"), boot = q("#boot"), desk = q("#desk"), light = q("#light"), reboot = q("#reboot");
  const strip = q("#strip"), blackOut = q("#black-out");
  [desk, light, reboot, boot].forEach((el) => gsap.set(el, { visibility: "hidden" }));
  qa(".win, .layer").forEach((el) => gsap.set(el, { autoAlpha: 0 }));

  // 1. The prompt: ">" and the cursor, the robin lands on it, "RobinOS" typed after it
  {
    gsap.set(logo, { visibility: "visible" });
    hide(logo, T.boot);
    show(logo, T.end);
    const svg = q("svg", logo), chev = q(".m-chev", svg), robin = q(".m-robin", svg);
    gsap.set([chev, robin, q(".url", logo)], { autoAlpha: 0 });
    for (const [prompt, land] of [[EV.prompt, EV.land], [EV.endPrompt, EV.endLand]]) {
      tl.set(chev, { autoAlpha: 1 }, prompt);
      tl.fromTo(robin, { y: -90, autoAlpha: 0 }, { y: 0, autoAlpha: 1, duration: 0.42, ease: "quint", immediateRender: false }, land - 0.42);
      tl.fromTo(robin, { scaleY: 0.93, transformOrigin: "50% 100%" }, { scaleY: 1, duration: SPRING_TIME, ease: spring, immediateRender: false }, land);
    }
    tl.set(robin, { autoAlpha: 0 }, T.boot);
    tl.set(chev, { autoAlpha: 0 }, T.boot);
    tl.set(q(".url", logo), { autoAlpha: 1 }, EV.url);
    tl.to(blackOut, { opacity: 1, duration: DURATION - EV.fadeOut, ease: "none" }, EV.fadeOut);
  }

  // 2. Boot: hard cuts on the beat — boot menu, login (password typed), the real desktop
  {
    show(boot, T.boot);
    hide(boot, T.ws1);
    const grub = q("#boot-grub"), login = q("#boot-login"), shot = q("#boot-desktop");
    gsap.set([grub, login, shot], { autoAlpha: 0 });
    on(grub, T.boot); off(grub, T.login);
    on(login, T.login); off(login, T.desktopShot);
    on(shot, T.desktopShot);
  }

  // The narrator strip slides up with the boot and leaves with the desktop
  gsap.set(strip, { yPercent: 100 });
  tl.to(strip, { yPercent: 0, duration: 0.45, ease: "quint" }, T.boot);
  tl.to(strip, { yPercent: 100, duration: 0.35, ease: "none" }, EV.barOut);

  // 3. The desktop: the bar comes down, workspaces slide like Hyprland's slidefade 12%
  const bar = q("#bar");
  show(desk, T.ws1);
  hide(desk, EV.powerOff);
  show(desk, T.ws5);
  hide(desk, T.end);
  gsap.set(bar, { yPercent: -100 });
  tl.to(bar, { yPercent: 0, duration: 0.4, ease: "quint" }, T.ws1);
  tl.to(bar, { yPercent: -100, duration: 0.3, ease: "none" }, EV.barOut);

  const wsEls = qa(".ws", desk);
  gsap.set(wsEls, { autoAlpha: 0 });
  WORKSPACES.forEach((w, i) => {
    const el = wsEls[w.n - 1];
    if (i === 0) { on(el, w.at); }
    else {
      const prev = wsEls[WORKSPACES[i - 1].n - 1];
      const slide = W * 0.12;
      tl.to(prev, { x: -slide, autoAlpha: 0, duration: 0.45, ease: "quint" }, w.at);
      tl.fromTo(el, { x: slide, autoAlpha: 0 }, { x: 0, autoAlpha: 1, duration: 0.45, ease: "quint", immediateRender: false }, w.at);
    }
  });
  // Bar: the active workspace pill and the focused window's title
  for (const b of [bar, q("#bar-light")]) {
    b.innerHTML = barHtml();
  }
  const pillX = (n) => (n - 1) * 41;
  for (const b of [bar, q("#bar-light")]) {
    const pill = q(".ws-pill", b), nums = qa(".wsnums span", b), title = q(".title", b);
    gsap.set(pill, { x: 0 });
    nums[0].classList.add("on");
    WORKSPACES.forEach((w) => {
      tl.to(pill, { x: pillX(w.n), duration: 0.4, ease: "quint" }, w.at);
      nums.forEach((s, i) => tl.set(s, { className: i === w.n - 1 ? "on" : "" }, w.at));
      tl.set(title, { textContent: w.title }, w.at);
    });
  }

  // Workspace 1: the launcher finds Notepad by its Windows name, then Windows shortcuts
  {
    const L = q("#l-launcher"), result = q("#l-launcher-result"), typing = q(".search-type", L);
    placeLayer(L, "center");
    gsap.set(result, { autoAlpha: 0 });
    layerIn(L, EV.launcher + 0.08);
    tl.set(typing, { autoAlpha: 1 }, EV.launcherType);
    gsap.set(typing, { autoAlpha: 0 });
    tl.set(result, { autoAlpha: 1 }, EV.launcherResult);
    tl.set(typing, { autoAlpha: 0 }, EV.launcherResult);
    layerOut(L, EV.launcherClose);
    for (const [id, at, out] of [["#l-alttab", EV.altTab, EV.altTabOut], ["#l-clipboard", EV.clipboard, EV.clipboardOut], ["#l-emoji", EV.emoji, EV.emojiOut]]) {
      const layer = q(id);
      placeLayer(layer, "center");
      layerIn(layer, at + 0.08);
      layerOut(layer, out);
    }
  }

  // Workspace 2: a terminal answers a Windows command; the mission window splits the workspace
  {
    const t1 = q("#w-term1"), mission = q("#w-mission");
    windowIn(t1, EV.term1, dwindle(1)[0]);
    gsap.set(qa('[data-at="hint"]', t1), { autoAlpha: 0 });
    tl.set(qa('[data-at="hint"]', t1), { autoAlpha: 1 }, EV.hint);
    const two = dwindle(2);
    windowTo(t1, EV.missionOpen, two[0]);
    inactive(t1, EV.missionOpen);
    windowIn(mission, EV.missionOpen + 0.02, two[1]);
  }

  // Workspace 3: launcher and quick settings over a terminal; the pointer turns on light mode
  {
    const t3 = q("#w-term3"), L3 = q("#l-launcher3"), qs = q("#l-qs");
    windowIn(t3, EV.ws3Term, dwindle(1)[0]);
    placeLayer(L3, "center-left");
    placeLayer(qs, "right");
    layerIn(L3, EV.ws3Launcher + 0.08);
    layerIn(qs, EV.quickSettings + 0.08);
    // The light copy, same layout
    const t3l = q("#w-term3-light"), L3l = q("#l-launcher3-light");
    gsap.set(t3l, { ...css(dwindle(1)[0]), autoAlpha: 1 });
    placeLayer(L3l, "center-left");
    gsap.set(L3l, { autoAlpha: 1 });
    gsap.set(q("#bar-light"), { yPercent: 0 });

    // Dark mode tile in the quick settings screenshot: (1424..1580, 168..226) → its center on the stage
    const s = q(".crop", qs)._s;
    const tile = { x: parseFloat(qs.style.left) + (1502 - 1246) * s, y: BAR + parseFloat(qs.style.top) + (197 - 40) * s };
    const pointer = q("#pointer");
    gsap.set(pointer, { x: 980, y: 760, autoAlpha: 0 });
    tl.set(pointer, { autoAlpha: 1 }, EV.pointer - 0.2);
    tl.to(pointer, { x: tile.x - 6, y: tile.y - 4, duration: 0.55, ease: "quint" }, EV.pointer);
    tl.to(pointer, { scale: 0.86, duration: 0.07, ease: "none" }, EV.themeClick - 0.05);
    tl.to(pointer, { scale: 1, duration: 0.15, ease: "quint" }, EV.themeClick + 0.05);
    // Clicking toggles the theme: the panel closes, light spreads from the tile
    layerOut(qs, EV.themeClick);
    show(light, EV.themeClick);
    const at = (r) => `circle(${r}px at ${tile.x}px ${tile.y}px)`;
    gsap.set(light, { clipPath: at(0) });
    tl.to(light, { clipPath: at(2300), duration: 0.75, ease: "quint" }, EV.themeClick);
    tl.to(light, { clipPath: at(0), duration: 0.5, ease: "quint" }, EV.themeBack);
    hide(light, EV.themeBack + 0.5);
    tl.set(pointer, { autoAlpha: 0 }, EV.themeBack + 0.5);
  }

  // Workspace 4: an update, a reboot, and the snapshots it left in the boot menu
  {
    const t4 = q("#w-term4");
    windowIn(t4, EV.term4, dwindle(1)[0]);
    tl.set(blackOut, { opacity: 1 }, EV.powerOff);
    tl.set(blackOut, { opacity: 0 }, EV.grub);
    show(reboot, EV.grub);
    hide(reboot, T.ws5);
    const menu = q("#grub-menu"), pick = q("#grub-pick");
    gsap.set(pick, { autoAlpha: 0 });
    on(pick, EV.grubEnter);
    off(menu, EV.grubEnter);
  }

  // Workspace 5: real panels tile in one per beat, then everything closes
  {
    const wins = ["#w-cal", "#w-sound", "#w-emoji", "#w-qs"].map((id) => q(id));
    wins.forEach((win, i) => {
      const at = EV.tiles[i], rects = dwindle(i + 1);
      for (let j = 0; j < i; j++) { windowTo(wins[j], at, rects[j]); inactive(wins[j], at); }
      windowIn(win, at, rects[i]);
    });
    wins.forEach((win, i) => windowOut(win, EV.allClose + i * 0.03));
  }

  tl.to({}, { duration: 0 }, DURATION); // the timeline is exactly DURATION long
}

// ── keys at the right of the prompt ──
function buildKeys() {
  const box = q("#keys");
  KEYS.forEach((k, i) => {
    const set = document.createElement("div");
    set.className = "keyset";
    set.innerHTML = k.keys.map((key) => `<span class="cap"><kbd>${key}</kbd></span>`).join("<i>+</i>").replaceAll("<i>+</i>", k.keys[0] === "↓" ? "" : "<i>+</i>");
    box.appendChild(set);
    const end = Math.min(KEYS[i + 1]?.at ?? Infinity, k.at + 1.6);
    tl.fromTo(set, { autoAlpha: 0, y: 10 }, { autoAlpha: 1, y: 0, duration: 0.18, ease: "quint", immediateRender: false }, k.at);
    qa("kbd", set).forEach((kbd, j) => {
      tl.to(kbd, { y: 4, duration: 0.05, ease: "none" }, k.at + 0.04 + j * 0.06);
      tl.to(kbd, { y: 0, duration: 0.16, ease: "quint" }, k.at + 0.18 + j * 0.06);
    });
    tl.to(set, { autoAlpha: 0, duration: 0.15, ease: "none" }, end - 0.15);
  });
}

// ── typing and carets, from t ──
const targets = {};
function setupTyping() {
  for (const ev of TYPING) (targets[ev.target] ??= []).push(ev);
  for (const list of Object.values(targets)) list.sort((a, b) => a.at - b.at);
  // The two names on the prompt: a hidden copy keeps the layout still while the name is typed
  const name = q("#logo .name");
  name.innerHTML = '<span class="ghost">RobinOS</span><span class="typed" data-type="logo-name"></span>';
}
function typedAt(target, t) {
  const list = targets[target];
  if (!list) return { text: "", typing: false, since: 0 };
  let ev = null;
  for (const e of list) if (e.at <= t) ev = e;
  if (!ev) return { text: "", typing: false, since: 0 };
  const step = ev.fast ? TYPE_FAST : TYPE;
  const n = Math.min(ev.text.length, Math.floor((t - ev.at) / step) + 1);
  return { text: ev.text.slice(0, n), typing: n < ev.text.length, since: ev.at + ev.text.length * step };
}
// Terminal carets blink at the beat's eighth (as a cursor blinks), and stay solid while typing
const blinkOn = (t) => Math.floor(t / (BEAT / 2)) % 2 === 0;
const CARET_HIDE = { "term1-1": EV.hint };

function ambient(t) {
  for (const el of qa("[data-type]")) {
    const { text } = typedAt(el.dataset.type, t);
    if (el.textContent !== text) el.textContent = text;
  }
  for (const el of qa("[data-caret]")) {
    const id = el.dataset.caret, target = { "term1-1": "term1-cmd1", "term1-2": "term1-cmd2", term4: "term4-cmd", caption: "caption" }[id];
    const { typing } = typedAt(target, t);
    let on = typing || blinkOn(t);
    if (CARET_HIDE[id] !== undefined && t >= CARET_HIDE[id]) on = false;
    el.style.opacity = on ? 1 : 0;
  }
  // The prompt's own cursor (the mark's bar) blinks until the robin lands on it
  const cursor = q("#logo .m-cursor");
  const waiting = (t >= EV.prompt && t < EV.land) || (t >= EV.endPrompt && t < EV.endLand);
  cursor.style.opacity = t < EV.prompt ? 0 : waiting ? (blinkOn(t) ? 1 : 0) : 1;
  // Login: five dots
  const dots = Math.max(0, Math.min(5, Math.floor((t - EV.passwordDots) / TYPE) + 1));
  const pw = q("#pw");
  const want = t >= EV.passwordDots ? "•".repeat(dots) : "";
  if (pw.textContent !== want) pw.textContent = want;
  pw.style.opacity = t >= EV.passwordDots ? 1 : 0;
  fitWindowCrops();
}

// The login screenshot has a placeholder in the password field; a patch in the field's own color covers it
async function sampleColors() {
  const sample = async (src, x, y) => {
    const img = new Image();
    img.src = `assets/${src}`;
    await img.decode();
    const c = document.createElement("canvas");
    c.width = 1600; c.height = 900;
    const g = c.getContext("2d");
    g.drawImage(img, 0, 0);
    const [r, gr, b] = g.getImageData(x, y, 1, 1).data;
    return `rgb(${r}, ${gr}, ${b})`;
  };
  // login.png password field (634..966, 544..584), cropped from x 53 at 1.2857x (cover)
  const s = 1080 / 840, pw = q("#pw");
  Object.assign(pw.style, {
    left: `${(640 - 53) * s + (W - 1493 * s) / 2}px`, top: `${548 * s}px`, width: `${320 * s}px`, height: `${32 * s}px`,
    paddingLeft: `${10 * s}px`, background: await sample("login.png", 900, 564), borderRadius: "6px",
  });
  // launcher-dark.png search field (520..1060, 165..195): covered while "notepad" is typed
  const L = q("#l-launcher"), ls = Number(q(".crop", L).dataset.scale), st = q(".search-type", L);
  Object.assign(st.style, {
    left: `${(522 - 480) * ls}px`, top: `${(166 - 153) * ls}px`, width: `${(1060 - 522) * ls}px`, height: `${28 * ls}px`,
    background: await sample("launcher-dark.png", 800, 168),
  });
}

async function init() {
  qa("[data-mark]").forEach((el) => { el.innerHTML = markSvg(); });
  setupTyping();
  await document.fonts.load('600 46px "Pretendard"');
  await document.fonts.load('600 150px "Geist"');
  await document.fonts.load('400 30px "Geist Mono"');
  await document.fonts.ready;
  setupCrops();
  await sampleColors();
  // Make sure every screenshot is decoded before the first frame
  const srcs = [...new Set(qa(".crop").map((el) => el.dataset.src))];
  await Promise.all(srcs.map((src) => { const i = new Image(); i.src = `assets/${src}`; return i.decode().catch(() => {}); }));
  build();
  buildKeys();
  tl.seek(0, false);
  ambient(0);

  const stage = q("#stage");
  window.__video = {
    ready: true,
    duration: DURATION,
    fps: FPS,
    // For the recorder: move to exactly t seconds and wait until it is painted
    seek: (t) => {
      tl.seek(t, false);
      ambient(t);
      return new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(() => resolve(true))));
    },
  };
  if (RENDER) return;

  // Preview: fit the window; click or Space plays with sound
  const fit = () => {
    const s = Math.min(innerWidth / 1920, innerHeight / 1080);
    stage.style.transform = `translate(${(innerWidth - 1920 * s) / 2}px, ${(innerHeight - 1080 * s) / 2}px) scale(${s})`;
  };
  fit();
  addEventListener("resize", fit);
  const audio = new Audio("out/audio.wav");
  audio.preload = "auto";
  const sync = () => { audio.currentTime = tl.time(); if (!tl.paused()) audio.play().catch(() => {}); };
  const toggle = () => {
    if (tl.progress() >= 1) tl.seek(0, false);
    if (tl.paused()) { tl.play(); sync(); } else { tl.pause(); audio.pause(); }
  };
  gsap.ticker.add(() => ambient(tl.time()));
  tl.seek(params.has("t") ? parseFloat(params.get("t")) : 0, false);
  addEventListener("click", toggle);
  addEventListener("keydown", (e) => {
    if (e.code === "Space") { e.preventDefault(); toggle(); }
    if (e.code === "ArrowRight") { tl.seek(Math.min(DURATION, tl.time() + 2), false); sync(); }
    if (e.code === "ArrowLeft") { tl.seek(Math.max(0, tl.time() - 2), false); sync(); }
    if (e.code === "Home") { tl.seek(0, false); sync(); }
  });
}
init();
