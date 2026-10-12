// RobinOS intro video: one paused GSAP timeline.
//   preview: index.html          (click or Space = play/pause, ←/→ = 2 s, ?t=12 starts at 12 s)
//   render:  index.html?render   (render.mjs calls __video.seek(t) for every frame and captures it)
// Everything that changes by itself (typing, carets, counting, drifting light)
// is computed from t in ambient(), never by CSS, so a frozen frame is always
// the same. Times come from cues.js in beats; b(n) turns them into seconds.
import { gsap } from "./node_modules/gsap/index.js";
import { CustomEase } from "./node_modules/gsap/CustomEase.js";
import { FPS, BEAT, TYPE, DURATION, SONG, S, TYPING, PRESSES, ENTERS, b } from "./cues.js";

gsap.registerPlugin(CustomEase);
// Keynote-style curves: a long, soft landing for reveals, a quick lift for exits
CustomEase.create("land", "0.16, 1, 0.3, 1");
CustomEase.create("lift", "0.7, 0, 0.84, 0");
CustomEase.create("glide", "0.65, 0, 0.35, 1");
// RobinOS's own window spring (hl.curve "easy" in desktop/hypr/robinos.lua):
// mass 1, stiffness 238.12, damping 24.21, closed form over 0.5 s
const SPRING_TIME = 0.5;
const spring = (() => {
  const w0 = Math.sqrt(238.1191), zeta = 24.21279333 / (2 * w0), wd = w0 * Math.sqrt(1 - zeta * zeta);
  const a = zeta * w0 * SPRING_TIME, c = wd * SPRING_TIME;
  return (p) => (p >= 1 ? 1 : 1 - Math.exp(-a * p) * (Math.cos(c * p) + (a / c) * Math.sin(c * p)));
})();

const params = new URLSearchParams(location.search);
const RENDER = params.has("render");
const q = (s, root = document) => root.querySelector(s);
const qa = (s, root = document) => [...root.querySelectorAll(s)];
const W = 1920, H = 1080;

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

// ── words: every word (or letter) becomes an inline block that can move on its own ──
function splitWords(el, letters = false) {
  for (const node of [...el.childNodes]) {
    if (node.nodeType === Node.ELEMENT_NODE) { splitWords(node, letters); continue; }
    if (node.nodeType !== Node.TEXT_NODE) continue;
    const frag = document.createDocumentFragment();
    for (const part of node.textContent.split(letters ? /()/ : /(\s+)/)) {
      if (!part) continue;
      if (/^\s+$/.test(part)) { frag.appendChild(document.createTextNode(part)); continue; }
      const w = document.createElement("span");
      w.className = "w";
      w.textContent = part;
      frag.appendChild(w);
    }
    node.replaceWith(frag);
  }
}
const wordsOf = (el) => (el.classList?.contains("w") ? [el] : qa(".w", el));

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
    if (fit === "display") {        // fills the booting display (1200x675)
      const s = Math.min(1200 / w, 675 / h);
      applyCrop(el, s);
      Object.assign(el.style, { left: `${(1200 - w * s) / 2}px`, top: `${(675 - h * s) / 2}px` });
    } else if (fit === "tile") {    // a bento tile: under the label, may run off the bottom edge
      const tile = el.parentElement, [, , tw, th] = tile.dataset.rect.split(",").map(Number);
      const aw = tw - 64, ah = th - 108;
      const s = Math.min(aw / w, (ah * 1.25) / h);
      applyCrop(el, s);
      const top = h * s > ah ? 80 : 80 + (ah - h * s) / 2;
      Object.assign(el.style, { left: `${(tw - w * s) / 2}px`, top: `${top}px` });
    } else {
      applyCrop(el, Number(el.dataset.scale || 1));
    }
  }
}
// Read one pixel of a screenshot, to cover printed text with its own background
const images = {};
async function sample(src, x, y) {
  if (!images[src]) {
    const img = new Image();
    img.src = `assets/${src}`;
    await img.decode();
    const c = document.createElement("canvas");
    c.width = 1600; c.height = 900;
    c.getContext("2d", { willReadFrequently: true }).drawImage(img, 0, 0);
    images[src] = c.getContext("2d", { willReadFrequently: true });
  }
  const [r, g, bl] = images[src].getImageData(x, y, 1, 1).data;
  return `rgb(${r}, ${g}, ${bl})`;
}
async function setupPatches() {
  // Boot menu lines about security are covered (design.md T-151: the product text will change)
  const s = 1200 / 1600;
  for (const p of qa(".patch")) {
    const [x, y, w, h] = p.dataset.rect.split(",").map(Number);
    Object.assign(p.style, { left: `${x * s}px`, top: `${y * s}px`, width: `${w * s}px`, height: `${h * s}px`, background: await sample(p.dataset.patch, x + 2, y + 2) });
  }
  // login.png password field (634..966, 544..584): dots are typed into a patch of the field's color
  const ls = Math.min(1200 / 1493, 675 / 840), pw = q("#pw");
  Object.assign(pw.style, {
    left: `${(640 - 53) * ls + (1200 - 1493 * ls) / 2}px`, top: `${548 * ls + (675 - 840 * ls) / 2}px`,
    width: `${320 * ls}px`, height: `${32 * ls}px`, paddingLeft: `${10 * ls}px`,
    background: await sample("login.png", 900, 564), borderRadius: "5px",
  });
  // launcher-dark.png search field (520..1060, 165..195): covered while "notepad" is typed
  const card = q("#c-launcher"), cs = Number(q(".crop", card).dataset.scale), st = q("#search-type");
  Object.assign(st.style, {
    left: `${(522 - 480) * cs}px`, top: `${(166 - 153) * cs}px`, width: `${(1060 - 522) * cs}px`, height: `${28 * cs}px`,
    background: await sample("launcher-dark.png", 800, 168),
  });
}

// ── the timeline ──
const tl = gsap.timeline({ paused: true });
// Scenes are shown with visibility; anything inside a scene uses autoAlpha
// (a child set to visibility: visible would stay on screen after its scene is hidden).
function scene(el, from, to) {
  gsap.set(el, { visibility: "hidden" });
  tl.set(el, { visibility: "visible" }, b(from));
  if (to !== undefined) tl.set(el, { visibility: "hidden" }, b(to));
}
// Words rise out of a blur and settle (one per beat, or a quick ripple)
function reveal(target, at, { stagger = 0.07, dur = 1.05, y = 46, blur = 18, scale = 0.97 } = {}) {
  const ws = Array.isArray(target) ? target : wordsOf(target);
  tl.fromTo(ws, { autoAlpha: 0, y, scale, filter: `blur(${blur}px)` },
    { autoAlpha: 1, y: 0, scale: 1, filter: "blur(0px)", duration: dur, ease: "land", stagger, immediateRender: false }, at);
}
function conceal(target, at, { stagger = 0.025, dur = 0.42, y = -26 } = {}) {
  const ws = Array.isArray(target) ? target : wordsOf(target);
  tl.to(ws, { autoAlpha: 0, y, filter: "blur(14px)", duration: dur, ease: "lift", stagger }, at);
}
// Something solid (a screen, a card) arrives from depth and lands
function arrive(el, at, from = {}, dur = 1.15) {
  tl.fromTo(el, { autoAlpha: 0, y: 90, z: -240, rotationX: 18, filter: "blur(14px)", ...from },
    { autoAlpha: 1, y: 0, z: 0, rotationX: 0, rotationY: 0, x: 0, scale: 1, filter: "blur(0px)", duration: dur, ease: "land", immediateRender: false }, at);
}
function leave(el, at, to = {}, dur = b(1)) {
  tl.to(el, { autoAlpha: 0, filter: "blur(18px)", duration: dur, ease: "lift", ...to }, at);
}

// The soft lights move to a new place for every scene
const GLOW_AT = [
  [S.logo, [[960, 520], [760, 700], [1180, 380]], 0.55],
  [S.hero, [[960, 470], [520, 820], [1440, 300]], 1],
  [S.screen, [[960, 860], [360, 260], [1560, 520]], 0.85],
  [S.familiar, [[1330, 560], [1650, 940], [380, 180]], 0.85],
  [S.terminal, [[760, 640], [1500, 420], [300, 900]], 0.8],
  [S.bento, [[960, 640], [300, 300], [1640, 820]], 0.8],
  [S.finale, [[960, 470], [640, 760], [1300, 300]], 1],
];
function buildGlows() {
  const glows = qa(".glow");
  gsap.set("#glows", { opacity: 0 });
  GLOW_AT.forEach(([beat, pts, level], i) => {
    const at = b(beat);
    glows.forEach((g, j) => {
      const [x, y] = pts[j], to = { x: x - 960, y: y - 540 };
      if (i === 0) gsap.set(g, to);
      else tl.to(g, { ...to, duration: 2.2, ease: "glide" }, at - 0.3);
    });
    tl.to("#glows", { opacity: level, duration: i === 0 ? b(4) : 0.6, ease: i === 0 ? "sine.inOut" : "power2.out" }, at);
  });
}

function build() {
  const blackOut = q("#black-out"), vignette = q(".vignette");
  buildGlows();

  // 0–8: the chevron draws, the cursor appears, the robin lands on it, the name rises
  {
    const el = q("#s-logo");
    scene(el, S.logo, S.hero);
    const lockup = q(".lockup", el), slot = q(".mark-slot", el), svg = q("svg", el);
    const chev = q(".m-chev", svg), cursor = q(".m-cursor", svg), robin = q(".m-robin", svg);
    const wm = q(".wordmark", el), letters = wordsOf(q(".wm-text", wm)), sweep = q(".wm-sweep", wm);
    const len = chev.getTotalLength();
    // (hidden until it draws: a round cap on a zero-length dash still paints a dot)
    gsap.set(chev, { strokeDasharray: len, strokeDashoffset: len, autoAlpha: 0 });
    gsap.set(cursor, { scaleX: 0, transformOrigin: "0% 50%" });
    gsap.set(robin, { autoAlpha: 0 });
    gsap.set(letters, { autoAlpha: 0 });
    // The mark starts alone in the middle and makes room for the name
    gsap.set(slot, { x: (wm.offsetWidth + 4) / 2 });
    tl.set(chev, { autoAlpha: 1 }, b(0.5));
    tl.to(chev, { strokeDashoffset: 0, duration: b(1.2), ease: "glide" }, b(0.5));
    tl.to(cursor, { scaleX: 1, duration: b(0.9), ease: "land" }, b(1.5));
    tl.fromTo(robin, { y: -170, autoAlpha: 0 }, { y: 0, autoAlpha: 1, duration: 0.42, ease: "power2.in", immediateRender: false }, b(3) - 0.42);
    tl.fromTo(robin, { scaleY: 0.88, scaleX: 1.05, transformOrigin: "50% 100%" }, { scaleY: 1, scaleX: 1, duration: SPRING_TIME, ease: spring, immediateRender: false }, b(3));
    tl.to(slot, { x: 0, duration: b(1.8), ease: "glide" }, b(3.7));
    reveal(letters, b(4.1), { stagger: 0.045, dur: 1.2, y: 60, blur: 16 });
    tl.fromTo(sweep, { backgroundPosition: "100% 0" }, { backgroundPosition: "0% 0", duration: b(1.6), ease: "power2.inOut", immediateRender: false }, b(5.8));
    tl.to(lockup, { scale: 1.14, autoAlpha: 0, filter: "blur(24px)", duration: b(0.85), ease: "lift" }, b(7.15));
  }

  // 8–16: the statement, word by word on the beat
  {
    const el = q("#s-hero");
    scene(el, S.hero, S.screen);
    const hero = q(".hero", el), h1 = q("h1", el);
    const [w1, w2, w3, w4] = wordsOf(h1);
    gsap.set(wordsOf(hero), { autoAlpha: 0 });
    reveal(q(".eyebrow", el), b(8), { dur: 0.9 });
    [[w1, 8], [w2, 8.5], [w3, 10], [w4, 10.5]].forEach(([w, at]) => reveal([w], b(at), { y: 70, blur: 24, scale: 0.92, dur: 1.2 }));
    reveal(q(".sub", el), b(12), { stagger: 0.06 });
    tl.fromTo(h1, { letterSpacing: "-0.02em" }, { letterSpacing: "-0.055em", duration: b(7), ease: "power2.out", immediateRender: false }, b(8));
    tl.fromTo(hero, { scale: 1 }, { scale: 1.04, duration: b(7), ease: "none", immediateRender: false }, b(8));
    tl.to(hero, { scale: 1.3, autoAlpha: 0, filter: "blur(30px)", duration: b(1), ease: "lift" }, b(15));
  }

  // 16–24: a screen rises from lying flat and boots: boot menu → login → desktop
  {
    const el = q("#s-screen");
    scene(el, S.screen, S.familiar);
    const display = q("#display"), grub = q("#sc-grub"), login = q("#sc-login"), desk = q("#sc-desk"), flash = q("#sc-flash");
    const caption = q("#screen-caption");
    gsap.set([login, desk], { autoAlpha: 0 });
    gsap.set(wordsOf(caption), { autoAlpha: 0 });
    tl.fromTo(display, { autoAlpha: 0, y: 420, z: -300, rotationX: 68, transformOrigin: "50% 100%" },
      { autoAlpha: 1, y: 0, z: 0, rotationX: 0, duration: b(2.6), ease: "land", immediateRender: false }, b(16));
    tl.to(display, { rotationY: -3, y: -10, duration: b(4.5), ease: "sine.inOut" }, b(18.6));
    tl.set(grub, { autoAlpha: 0 }, b(18));
    tl.set(login, { autoAlpha: 1 }, b(18));
    // Enter on the password, then the desktop
    tl.fromTo(desk, { autoAlpha: 0, scale: 1.04 }, { autoAlpha: 1, scale: 1, duration: 0.6, ease: "land", immediateRender: false }, b(ENTERS[0]) + 0.08);
    tl.fromTo(flash, { opacity: 0.32 }, { opacity: 0, duration: 0.7, ease: "power2.out", immediateRender: false }, b(ENTERS[0]) + 0.08);
    reveal(caption, b(20.5), { stagger: 0.08 });
    conceal(caption, b(22.9));
    leave(display, b(23), { scale: 1.85, y: 60 });
  }

  // 24–36: Windows habits: keycaps on the left, real panels landing in a deck on the right
  {
    const el = q("#s-familiar");
    scene(el, S.familiar, S.terminal);
    const h2 = q("h2", el), items = qa(".sub-item", el);
    gsap.set(wordsOf(el), { autoAlpha: 0 });
    reveal(q(".line", h2), b(24));
    reveal(q(".line.grad", h2), b(24.5), { y: 60, blur: 22 });
    // Keycaps for each shortcut, pressed on its beat
    const row = q("#keyrow"), sets = [];
    PRESSES.forEach((p, i) => {
      const set = document.createElement("div");
      set.className = "keyset";
      set.innerHTML = p.keys.map((k) => `<span class="cap${k === "Space" ? " wide" : ""}">${k}</span>`).join("<i>+</i>");
      row.appendChild(set);
      sets.push(set);
      gsap.set(set, { autoAlpha: 0 });
      const at = b(p.at);
      tl.fromTo(set, { autoAlpha: 0, y: 50, filter: "blur(10px)" }, { autoAlpha: 1, y: 0, filter: "blur(0px)", duration: 0.55, ease: "land", immediateRender: false }, at - 0.32);
      qa(".cap", set).forEach((cap, j) => {
        gsap.set(cap, { "--press": 0 });
        tl.to(cap, { "--press": 1, duration: 0.07, ease: "power2.out" }, at + j * 0.08);
        tl.to(cap, { "--press": 0, duration: 0.45, ease: "land" }, at + 0.3 + j * 0.03);
      });
      const end = i + 1 < PRESSES.length ? b(PRESSES[i + 1].at) - 0.5 : b(35);
      tl.to(set, { autoAlpha: 0, y: -24, filter: "blur(8px)", duration: 0.3, ease: "lift" }, end);
      // The line that goes with it; the one before steps back
      reveal(items[i], at + 0.05, { stagger: 0.05, dur: 0.9, y: 30, blur: 12 });
      gsap.set(items[i], { color: "#fafafa" });
      if (i > 0) tl.to(items[i - 1], { color: "#52525b", duration: 0.5, ease: "power2.out" }, at);
    });

    // The deck: each panel lands in front, the earlier ones step back and up
    const cards = ["#c-launcher", "#c-alttab", "#c-emoji"].map((id) => q(id, el));
    const CX = 1380, CY = 570;
    cards.forEach((c, i) => {
      const crop = q(".crop", c), w = crop.offsetWidth, h = crop.offsetHeight;
      Object.assign(c.style, { width: `${w}px`, height: `${h}px`, left: `${CX - w / 2}px`, top: `${CY - h / 2}px` });
      gsap.set(c, { autoAlpha: 0, rotationY: -10, rotationX: 4 });
      const at = b(PRESSES[i].at) + 0.06;
      tl.fromTo(c, { autoAlpha: 0, y: 110, z: -320, rotationY: -28, rotationX: 16, filter: "blur(14px)" },
        { autoAlpha: 1, y: 0, z: 0, rotationY: -10, rotationX: 4, filter: "blur(0px)", duration: 1.1, ease: "land", immediateRender: false }, at);
      for (let j = 0; j < i; j++) {
        const depth = i - j;
        tl.to(cards[j], { x: 110 * depth, y: -130 * depth, z: -340 * depth, rotationY: -14, autoAlpha: depth === 1 ? 0.5 : 0.22, filter: `blur(${2 * depth}px)`, duration: 1.0, ease: "land" }, at);
      }
    });
    const result = q("#c-launcher-result"), typing = q("#search-type");
    gsap.set([result, typing], { autoAlpha: 0 });
    tl.set(typing, { autoAlpha: 1 }, b(TYPING[0].at));
    const found = b(TYPING[0].at) + TYPING[0].text.length * TYPE + 0.12;
    tl.set(result, { autoAlpha: 1 }, found);
    tl.set(typing, { autoAlpha: 0 }, found);
    // Slow drift of the whole deck, then everything leaves toward the camera
    tl.fromTo(q("#deck"), { rotationY: 0 }, { rotationY: -4, duration: b(10), ease: "none", immediateRender: false }, b(25));
    conceal(h2, b(34.9));
    conceal(items, b(34.95), { stagger: 0.03 });
    cards.forEach((c, i) => tl.to(c, { z: 700, autoAlpha: 0, filter: "blur(18px)", duration: b(1), ease: "lift" }, b(35) + (2 - i) * 0.04));
  }

  // 36–48: the terminal answers a Windows command, then 45 missions
  {
    const el = q("#s-terminal");
    scene(el, S.terminal, S.theme);
    const term = q("#term"), head = q("#term-head"), count = q("#count");
    gsap.set(wordsOf(el), { autoAlpha: 0 });
    gsap.set([q("#hint1"), q("#hint2"), q(".num", count)], { autoAlpha: 0 });
    arrive(term, b(36), { rotationX: 16, scale: 0.95 });
    const enter = b(ENTERS[1]);
    for (const [id, dt] of [["#hint1", 0.06], ["#hint2", b(0.5)]]) {
      tl.fromTo(q(id), { autoAlpha: 0, y: 18, filter: "blur(8px)" }, { autoAlpha: 1, y: 0, filter: "blur(0px)", duration: 0.7, ease: "land", immediateRender: false }, enter + dt);
    }
    tl.to(term, { scale: 1.035, duration: b(5), ease: "none" }, b(38.3));
    reveal(q("span", head), b(40));
    reveal(q(".grad", head), b(40.5), { y: 56, blur: 20 });
    conceal(head, b(43.3));
    tl.to(term, { x: -500, y: 10, scale: 0.62, rotationY: 20, duration: b(1.6), ease: "glide" }, b(43.4));
    tl.fromTo(q(".num", count), { autoAlpha: 0, scale: 0.8, filter: "blur(24px)" }, { autoAlpha: 1, scale: 1, filter: "blur(0px)", duration: 1.2, ease: "land", immediateRender: false }, b(44));
    reveal(q(".count-label", count), b(44.5));
    reveal(q(".count-sub", count), b(45), { stagger: 0.05 });
    leave(term, b(47.15), { y: -40 }, b(0.85));
    leave(count, b(47.2), { y: -40 }, b(0.8));
  }

  // 48–52: the breakdown: a dark launcher, then light spreads out from the middle
  {
    const dark = q("#s-theme"), light = q("#s-theme-light");
    scene(dark, S.theme, S.rollback);
    scene(light, S.theme + 1.6, S.rollback);
    gsap.set(wordsOf(dark), { autoAlpha: 0 });
    gsap.set(wordsOf(q("#day-word")), { autoAlpha: 0 });
    arrive(q(".theme-card", dark), b(48), { y: 40, z: -160, rotationX: 10 }, 1.3);
    for (const s of [dark, light]) tl.fromTo(s, { scale: 1 }, { scale: 1.04, duration: b(3.4), ease: "none", immediateRender: false }, b(48));
    reveal(q("#night-word"), b(48.5));
    const at = (r) => `circle(${r}px at 960px 410px)`;
    gsap.set(light, { clipPath: at(0) });
    tl.to(light, { clipPath: at(1500), duration: 1.25, ease: "power3.inOut" }, b(S.theme + 1.6));
    tl.to(vignette, { opacity: 0, duration: 0.8, ease: "power2.out" }, b(S.theme + 1.8));
    reveal(q("#day-word"), b(50.6));
    leave([q(".theme-card", light), q(".theme-caption", light)], b(51.35), { y: -40 }, 0.4);
  }

  // 52–60: snapshots on a timeline, a rollback, and the real boot menu that offers it
  {
    const el = q("#s-rollback");
    scene(el, S.rollback, S.bento);
    const head = q("#rb-head"), line = q("#timeline"), nodes = qa(".node", el), now = q("#now");
    const track = q(".track", el), fill = q("#track-fill"), rewind = q("#rewind"), card = q("#bootcard"), caption = q("#rb-caption");
    gsap.set(wordsOf(el), { autoAlpha: 0 });
    gsap.set([...nodes, now, card], { autoAlpha: 0 });
    reveal(q("span", head), b(52), { y: 60, blur: 22 });
    reveal(q(".grad", head), b(52.5), { y: 60, blur: 22 });
    tl.fromTo(track, { scaleX: 0 }, { scaleX: 1, duration: b(1.6), ease: "glide", immediateRender: false }, b(52.5));
    tl.fromTo(fill, { scaleX: 0 }, { scaleX: 1, duration: b(1.6), ease: "power2.inOut", immediateRender: false }, b(53));
    nodes.forEach((n, i) => {
      const at = b(53 + i * 0.75);
      tl.fromTo(n, { autoAlpha: 0, y: 24, scale: 0.7 }, { autoAlpha: 1, y: 0, scale: 1, duration: SPRING_TIME, ease: spring, immediateRender: false }, at);
      tl.set(n, { attr: { class: "node on" } }, at);
    });
    tl.fromTo(now, { autoAlpha: 0, y: -30 }, { autoAlpha: 1, y: 0, duration: SPRING_TIME, ease: spring, immediateRender: false }, b(54.6));
    // Roll back: the arrow draws, "now" slides back to before the update
    const paths = qa("path", rewind);
    paths.forEach((p) => { const l = p.getTotalLength(); gsap.set(p, { strokeDasharray: l, strokeDashoffset: l }); });
    gsap.set(rewind, { autoAlpha: 0 });
    tl.set(rewind, { autoAlpha: 1 }, b(55.5));
    tl.to(paths[0], { strokeDashoffset: 0, duration: 0.45, ease: "power2.inOut" }, b(55.5));
    tl.to(paths[1], { strokeDashoffset: 0, duration: 0.2, ease: "power2.out" }, b(55.5) + 0.4);
    tl.to(now, { x: -630, duration: b(1), ease: "glide" }, b(56));
    tl.to(fill, { scaleX: 0.5, duration: b(1), ease: "glide" }, b(56));
    tl.set(nodes[2], { attr: { class: "node gone" } }, b(56.4));
    tl.to(rewind, { autoAlpha: 0, duration: 0.3, ease: "none" }, b(57));
    // The real boot menu: the snapshot list, "pre" (before the update) highlighted
    tl.to(line, { y: -160, scale: 0.84, duration: b(1.2), ease: "glide" }, b(57));
    arrive(card, b(57.2), { y: 180, rotationX: 30, z: -200 }, 1.2);
    reveal(caption, b(58), { stagger: 0.05 });
    conceal([...wordsOf(head), ...wordsOf(caption)], b(59.2), { stagger: 0.015 });
    tl.to(el, { scale: 0.9, autoAlpha: 0, duration: b(0.75), ease: "lift" }, b(59.25));
    tl.to(vignette, { opacity: 1, duration: 0.8, ease: "power2.out" }, b(59.6));
  }

  // 60–72: everyday screens as a bento grid
  {
    const el = q("#s-bento");
    scene(el, S.bento, S.finale);
    const head = q("#bento-head"), tiles = qa(".tile", el), grid = q("#bento");
    gsap.set(wordsOf(el), { autoAlpha: 0 });
    tiles.forEach((t) => {
      const [x, y, w, h] = t.dataset.rect.split(",").map(Number);
      Object.assign(t.style, { left: `${x}px`, top: `${y}px`, width: `${w}px`, height: `${h}px` });
      gsap.set(t, { autoAlpha: 0 });
    });
    reveal(q("span", head), b(60));
    reveal(q(".grad", head), b(60.5), { y: 56, blur: 20 });
    tiles.forEach((t, i) => arrive(t, b(61 + i * 0.5), { y: 140, z: -380, rotationX: 24 }, 1.2));
    tl.fromTo(grid, { scale: 1, rotationX: 0 }, { scale: 1.035, rotationX: 3, duration: b(9), ease: "none", immediateRender: false }, b(61));
    conceal(head, b(70.4));
    tiles.forEach((t, i) => tl.to(t, { z: -700, autoAlpha: 0, filter: "blur(16px)", duration: b(1.2), ease: "lift" }, b(70.5) + Math.abs(i - 2.5) * 0.05));
  }

  // 72–80: the end: a ring of light, the mark and the name, the address
  {
    const el = q("#s-finale");
    scene(el, S.finale);
    const slot = q(".mark-slot", el), letters = wordsOf(q(".wm-text", el)), sweep = q(".wm-sweep", el);
    gsap.set(wordsOf(el), { autoAlpha: 0 });
    gsap.set([slot, q("#url")], { autoAlpha: 0 });
    tl.fromTo("#ring", { scale: 0.3, opacity: 1 }, { scale: 3.4, opacity: 0, duration: 1.6, ease: "land", immediateRender: false }, b(72));
    tl.fromTo(slot, { autoAlpha: 0, scale: 0.8, filter: "blur(20px)" }, { autoAlpha: 1, scale: 1, filter: "blur(0px)", duration: 1.2, ease: "land", immediateRender: false }, b(72));
    reveal(letters, b(72.25), { stagger: 0.04, dur: 1.2, y: 60, blur: 16 });
    reveal(q(".tagline", el), b(73.5), { stagger: 0.08 });
    tl.fromTo("#url", { autoAlpha: 0, y: 20 }, { autoAlpha: 1, y: 0, duration: 1, ease: "land", immediateRender: false }, b(74.5));
    tl.fromTo(sweep, { backgroundPosition: "100% 0" }, { backgroundPosition: "0% 0", duration: b(1.6), ease: "power2.inOut", immediateRender: false }, b(74.6));
    tl.fromTo(q(".lockup", el), { scale: 1 }, { scale: 1.03, duration: b(8), ease: "none", immediateRender: false }, b(72));
    tl.to(blackOut, { opacity: 1, duration: DURATION - b(78.4), ease: "power1.in" }, b(78.4));
  }

  tl.to({}, { duration: 0 }, DURATION); // the timeline is exactly DURATION long
}

// ── typing, carets, counting and light, from t ──
const blinkOn = (t) => Math.floor(t / (BEAT / 2)) % 2 === 0;
function typedAt(target, t) {
  const ev = TYPING.find((e) => e.target === target);
  if (!ev || t < b(ev.at)) return { text: "", typing: false };
  const n = Math.min(ev.text.length, Math.floor((t - b(ev.at)) / TYPE) + 1);
  return { text: ev.text.slice(0, n), typing: n < ev.text.length };
}
const inGroove = (t) => (t >= b(SONG.drop1) && t < b(SONG.breakdown)) || (t >= b(SONG.drop2) && t < b(SONG.finale));
const easeOutExpo = (p) => (p >= 1 ? 1 : 1 - Math.pow(2, -10 * p));
let glowEls, logoCursor, typeEls, searchCaret, cmdCaret, pwEl, countEl, beatEl;

function ambient(t) {
  for (const el of typeEls) {
    const { text } = typedAt(el.dataset.type, t);
    if (el.textContent !== text) el.textContent = text;
  }
  const search = typedAt("search", t);
  searchCaret.style.opacity = search.typing || blinkOn(t) ? 1 : 0;
  const cmd = typedAt("cmd", t);
  cmdCaret.style.opacity = t >= b(ENTERS[1]) ? 0 : cmd.typing || blinkOn(t) ? 1 : 0;
  // The prompt's cursor blinks until the robin lands on it
  logoCursor.style.opacity = t >= b(2.4) && t < b(3) && !blinkOn(t) ? 0 : 1;
  // Five password dots, one per 32nd note
  const dotsAt = b(18.5), dots = t >= dotsAt ? Math.min(5, Math.floor((t - dotsAt) / TYPE) + 1) : 0;
  const want = "•".repeat(dots);
  if (pwEl.textContent !== want) pwEl.textContent = want;
  // 45 missions, counted up with a long landing
  const n = Math.round(45 * easeOutExpo(Math.max(0, Math.min(1, (t - b(44)) / b(4)))));
  if (countEl.textContent !== String(n)) countEl.textContent = String(n);
  // Light: a slow drift, and a breath on every kick while the beat plays
  glowEls.forEach((g, i) => {
    const w = g.offsetWidth, h = g.offsetHeight;
    g.style.left = `${960 - w / 2 + Math.sin(t * (0.21 + i * 0.07) + i * 2.1) * 140}px`;
    g.style.top = `${540 - h / 2 + Math.cos(t * (0.17 + i * 0.05) + i * 1.3) * 90}px`;
  });
  const phase = (t / BEAT) % 1;
  const pulse = inGroove(t) ? Math.exp(-phase * 5) : t >= b(SONG.finale) ? Math.exp(-(t - b(SONG.finale)) * 1.5) : 0;
  beatEl.style.transform = `scale(${1 + 0.035 * pulse})`;
  beatEl.style.opacity = 0.82 + 0.18 * pulse;
}

async function init() {
  qa("[data-mark]").forEach((el) => { el.innerHTML = markSvg(); });
  await document.fonts.load('760 176px "Pretendard"');
  await document.fonts.load('650 156px "Geist"');
  await document.fonts.load('400 36px "Geist Mono"');
  await document.fonts.ready;
  qa("[data-words]").forEach((el) => splitWords(el));
  qa(".wm-text").forEach((el) => splitWords(el, true));
  setupCrops();
  await setupPatches();
  // Every screenshot is decoded before the first frame
  const srcs = [...new Set(qa(".crop").map((el) => el.dataset.src))];
  await Promise.all(srcs.map((src) => { const i = new Image(); i.src = `assets/${src}`; return i.decode().catch(() => {}); }));
  glowEls = qa(".glow");
  logoCursor = q("#s-logo .m-cursor");
  typeEls = qa("[data-type]");
  searchCaret = q("#search-type .caret");
  cmdCaret = q("#cmd-caret");
  pwEl = q("#pw");
  countEl = q("#count-num");
  beatEl = q("#glow-beat");
  // Scenes must be visible while they are measured; the timeline hides them again
  qa(".scene").forEach((s) => (s.style.visibility = "visible"));
  build();
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
    const s = Math.min(innerWidth / W, innerHeight / H);
    stage.style.transform = `translate(${(innerWidth - W * s) / 2}px, ${(innerHeight - H * s) / 2}px) scale(${s})`;
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
