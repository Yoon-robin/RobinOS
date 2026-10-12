// RobinOS intro video: one paused GSAP timeline.
//   preview: index.html          (click or Space = play/pause, ←/→ = 2 s, ?t=12 starts at 12 s)
//   render:  index.html?render   (render.mjs calls __video.seek(t) for every frame and captures it)
// Anything that moves by itself (cursor blink, typing, the drifting dot grid) is
// computed from t in ambient(), never by CSS, so a frozen frame is always the same.
import { gsap } from "./node_modules/gsap/index.js";
import { CustomEase } from "./node_modules/gsap/CustomEase.js";
import { FPS, DURATION, T, EV, COMBOS, CHIPS } from "./cues.js";

gsap.registerPlugin(CustomEase);
// Smooth deceleration without overshoot for arrivals; quick, quiet exits
CustomEase.create("out", "0.22, 1, 0.36, 1");
CustomEase.create("in", "0.5, 0, 0.75, 0");
CustomEase.create("inOut", "0.65, 0, 0.35, 1");

const params = new URLSearchParams(location.search);
const RENDER = params.has("render");
const REDUCED = !RENDER && matchMedia("(prefers-reduced-motion: reduce)").matches;
const q = (s, root = document) => root.querySelector(s);
const qa = (s, root = document) => [...root.querySelectorAll(s)];

// ── the RobinOS mark (assets/brand/robinos-mark.svg without its tile), in parts ──
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

function mount() {
  qa("[data-mark]").forEach((el) => { el.innerHTML = markSvg(); });
  // Headlines come in word by word
  qa("[data-words]").forEach((el) => {
    el.innerHTML = el.textContent.trim().split(/\s+/).map((w) => `<span class="w">${w}</span>`).join(" ");
  });
  q(".combos").innerHTML = COMBOS.map(({ keys, label }) =>
    `<div class="combo">${keys.map((k) => `<span class="key"><kbd>${k}</kbd></span>`).join("<i>+</i>")}<span class="lbl">${label}</span></div>`).join("");
  q(".chips").innerHTML = CHIPS.map((c) => `<span class="chip">${c}</span>`).join("");
}

// ── motion vocabulary ──
const tl = gsap.timeline({ paused: true, defaults: { ease: "out" } });

// Arrive: materialize (opacity + rise + blur), decelerating
function enter(targets, at, { y = 18, x = 0, blur = 10, scale = 1, dur = 0.7, stagger = 0 } = {}) {
  tl.fromTo(targets,
    { autoAlpha: 0, x, y, scale, filter: `blur(${blur}px)` },
    { autoAlpha: 1, x: 0, y: 0, scale: 1, filter: "blur(0px)", duration: dur, ease: "out", stagger }, at);
}
// Leave: smaller and quicker than the arrival
function exit(targets, at, { y = -10, blur = 6, dur = 0.38, stagger = 0 } = {}) {
  const dy = `${y < 0 ? "-=" : "+="}${Math.abs(y)}`;
  tl.to(targets, { autoAlpha: 0, y: dy, filter: `blur(${blur}px)`, duration: dur, ease: "in", stagger }, at);
}
// Shows a scene from `from` and hides it at `to` (null: stays to the end)
function scene(el, from, to) {
  if (from === 0) gsap.set(el, { visibility: "visible" });
  else tl.set(el, { visibility: "visible" }, from);
  if (to !== null) tl.set(el, { visibility: "hidden" }, to);
}
function heading(root, at) {
  const eyebrow = q(".eyebrow", root), words = qa(".h .w", root), sub = qa(".sub .w", root);
  enter(eyebrow, at, { y: 10, blur: 6, dur: 0.6 });
  enter(words, at + 0.1, { y: 22, blur: 12, dur: 0.75, stagger: 0.045 });
  if (sub.length) enter(sub, at + 0.1 + words.length * 0.045 + 0.2, { y: 14, blur: 8, dur: 0.6, stagger: 0.03 });
  return [eyebrow, q(".h", root), q(".sub", root)].filter(Boolean);
}

// Screens are 1600x900. A camera inside the frame pans and zooms without ever showing an edge.
function camAt(frame, s, fx = 800, fy = 450) {
  const w = frame.clientWidth, h = frame.clientHeight;
  const x = Math.min(0, Math.max(w - 1600 * s, w / 2 - fx * s));
  const y = Math.min(0, Math.max(h - 900 * s, h / 2 - fy * s));
  return { x, y, scale: s };
}
function fullView(frame) { return camAt(frame, frame.clientWidth / 1600); }
// Every .cam in a frame moves together (the dark/light wipe has two layers)
function zoom(frame, at, s, fx, fy, dur = 1.15) {
  tl.to(qa(".cam", frame), { ...camAt(frame, s, fx, fy), duration: dur, ease: "inOut" }, at);
}
// The frame arrives, then drifts closer very slowly until it leaves
function showShot(frame, at, until, { y = 50, x = 0 } = {}) {
  gsap.set(qa(".cam", frame), fullView(frame));
  enter(frame, at, { x, y, scale: 0.95, blur: 14, dur: 0.95 });
  tl.to(frame, { scale: 1.018, duration: until - at - 0.95, ease: "none" }, at + 0.95);
}
function glowTo(at, x, y, scale = 1) {
  tl.to(".glow", { x: x - 960, y: y - 540, scale, duration: 1.2, ease: "inOut" }, at);
}

// ── scenes ──
function build() {
  // 1. Intro: ">" draws, the cursor blinks, the robin lands on it, then the name
  {
    const root = q("#intro"), svg = q("svg", root);
    const chev = q(".m-chev", svg), robin = q(".m-robin", svg);
    const slot = q(".mark-slot", root), word = q(".word", root), tagline = q(".tagline", root);
    scene(root, 0, T.keys);
    const shift = (word.offsetWidth + parseFloat(getComputedStyle(q(".lockup", root)).columnGap)) / 2;
    gsap.set(slot, { x: shift, scale: 1.3 });
    gsap.set(chev, { strokeDasharray: 44, strokeDashoffset: 44 });
    tl.to(chev, { strokeDashoffset: 0, duration: 0.5, ease: "out" }, EV.chevron);
    // Lands on the beat (EV.land), slowing down into the cursor, then settles
    tl.fromTo(robin, { y: -78, autoAlpha: 0, filter: "blur(10px)" },
      { y: 0, autoAlpha: 1, filter: "blur(0px)", duration: 0.55, ease: "out" }, EV.land - 0.55);
    tl.fromTo(robin, { scaleY: 0.95, transformOrigin: "50% 100%" }, { scaleY: 1, duration: 0.3, ease: "out" }, EV.land);
    // The mark steps aside for the name, which is revealed left to right
    tl.to(slot, { x: 0, scale: 1, duration: 0.9, ease: "inOut" }, EV.word);
    tl.fromTo(word, { autoAlpha: 0, x: -24, filter: "blur(12px)", clipPath: "inset(0 100% 0 0)" },
      { autoAlpha: 1, x: 0, filter: "blur(0px)", clipPath: "inset(0 0% 0 0)", duration: 0.9, ease: "out" }, EV.word + 0.2);
    enter(tagline, EV.tagline, { y: 16, blur: 8, dur: 0.8 });
    exit([q(".lockup", root), tagline], EV.introOut, { dur: 0.42, stagger: 0.04 });
  }

  // 2. Shortcuts, each pressed as it lands (the modifier is held while the key goes down)
  {
    const root = q("#keys");
    scene(root, T.keys, T.launcher);
    glowTo(T.keys - 0.6, 960, 600, 1.1);
    const head = heading(root, EV.keysHead);
    const combos = qa(".combo", root);
    combos.forEach((combo, i) => {
      const at = EV.combos[i];
      enter(combo, at, { y: 24, blur: 10, dur: 0.6 });
      const [mod, key] = qa("kbd", combo);
      tl.to(mod, { y: 4, duration: 0.07, ease: "in" }, at + 0.22);
      tl.to(key, { y: 4, duration: 0.07, ease: "in" }, at + 0.3);
      tl.to(key, { y: 0, duration: 0.2, ease: "out" }, at + 0.42);
      tl.to(mod, { y: 0, duration: 0.2, ease: "out" }, at + 0.52);
    });
    exit(combos, EV.keysShot - 0.1, { y: -14, blur: 8, dur: 0.4, stagger: 0.04 });
    const shot = q("#shot-alttab");
    showShot(shot, EV.keysShot, EV.keysOut);
    enter(q(".chip-kbd", shot), EV.keysShot + 0.7, { y: 10, blur: 8, dur: 0.6 });
    exit([...head, shot], EV.keysOut, { stagger: 0.03 });
  }

  // 3. Launcher, then quick settings: same frame, the camera pushes in to each
  {
    const root = q("#launcher"), shot = q(".shot", root);
    scene(root, T.launcher, T.settings + 0.1);
    glowTo(T.launcher - 0.6, 1300, 500, 1);
    const head = heading(root, T.launcher + 0.1);
    showShot(shot, T.launcher + 0.05, T.settings, { y: 0, x: 40 });
    zoom(shot, EV.launcherZoom, 1.35, 800, 290);
    exit(head, T.settings - 0.45);
    tl.to(shot, { autoAlpha: 0, duration: 0.4, ease: "in" }, T.settings - 0.3);
  }
  {
    const root = q("#settings"), shot = q(".shot", root);
    scene(root, T.settings - 0.3, T.terminal);
    const head = heading(root, T.settings + 0.05);
    gsap.set(q(".cam", shot), fullView(shot));
    tl.fromTo(shot, { autoAlpha: 0, scale: 1.018 }, { autoAlpha: 1, duration: 0.4, ease: "out" }, T.settings - 0.3);
    tl.to(shot, { scale: 1.03, duration: T.terminal - T.settings, ease: "none" }, T.settings);
    zoom(shot, EV.settingsZoom, 1.4, 1420, 250);
    exit([...head, shot], EV.settingsOut, { stagger: 0.03 });
  }

  // 4. Terminal: typed in ambient(); shell output appears at once, as in a real terminal
  {
    const root = q("#terminal"), term = q(".term", root);
    scene(root, T.terminal, T.mission + 0.1);
    glowTo(T.terminal - 0.6, 960, 600, 1.15);
    const head = heading(root, T.terminal + 0.1);
    enter(term, T.terminal + 0.15, { y: 40, scale: 0.97, blur: 12, dur: 0.85 });
    gsap.set(["#l2", "#l3", "#l4"], { autoAlpha: 0 });
    tl.set("#l2", { autoAlpha: 1 }, EV.hint);
    tl.set("#l3", { autoAlpha: 1 }, EV.hint + 0.05);
    tl.set("#l4", { autoAlpha: 1 }, EV.hint + 0.3);
    exit(head, T.mission - 0.35);
    tl.to(term, { autoAlpha: 0, scale: 1.04, filter: "blur(10px)", duration: 0.45, ease: "in" }, T.mission - 0.3);
  }
  {
    const root = q("#mission"), shot = q(".shot", root);
    scene(root, T.mission - 0.1, T.labs);
    const head = heading(root, T.mission + 0.05);
    showShot(shot, T.mission - 0.05, EV.missionOut, { y: 30 });
    zoom(shot, EV.missionZoom, 1.25, 800, 400);
    exit([...head, shot], EV.missionOut, { stagger: 0.03 });
  }

  // 5. From power-on: boot menu, login and desktop arrive left to right, one per beat
  {
    const root = q("#power");
    scene(root, T.power, T.theme);
    glowTo(T.power - 0.6, 960, 600, 1.25);
    const head = heading(root, T.power + 0.1);
    const tiles = qa(".tile", root);
    tiles.forEach((tile, i) => {
      // Crops keep each screen's own identity line out of frame (data-cam = scale, focus x, focus y)
      const frame = q(".shot", tile), crop = frame.dataset.cam?.split(",").map(Number);
      gsap.set(q(".cam", frame), crop ? camAt(frame, ...crop) : fullView(frame));
      enter(tile, EV.tiles[i], { x: 28, y: 0, blur: 12, dur: 0.75 });
    });
    exit([...head, ...tiles], EV.powerOut, { stagger: 0.03 });
  }
  // Dark to light: the light screen wipes in over the dark one, with a bright edge
  {
    const root = q("#theme"), shot = q("#shot-theme"), divider = q(".divider", shot);
    scene(root, T.theme - 0.1, T.snapshot);
    glowTo(T.theme - 0.6, 1300, 500, 1);
    const head = heading(root, T.theme + 0.05);
    showShot(shot, T.theme, EV.themeOut, { y: 0, x: 40 });
    // Starts already on the launcher (the full screen also shows the lab entries)
    gsap.set(qa(".cam", shot), camAt(shot, 1.45, 800, 290));
    zoom(shot, EV.themeZoom, 1.6, 800, 290);
    const w = shot.clientWidth;
    tl.fromTo(q(".wipe", shot), { clipPath: "inset(0 100% 0 0)" }, { clipPath: "inset(0 0% 0 0)", duration: 1.0, ease: "inOut" }, EV.themeWipe);
    tl.fromTo(divider, { x: 0, opacity: 0 }, { x: w, duration: 1.0, ease: "inOut" }, EV.themeWipe);
    tl.to(divider, { opacity: 1, duration: 0.15, ease: "out" }, EV.themeWipe);
    tl.to(divider, { opacity: 0, duration: 0.2, ease: "in" }, EV.themeWipe + 0.8);
    exit([...head, shot], EV.themeOut, { stagger: 0.03 });
  }

  // 6. Snapshots: the boot menu lists them; the row lights up
  {
    const root = q("#snapshot"), shot = q(".shot", root);
    scene(root, T.snapshot, T.end);
    glowTo(T.snapshot - 0.6, 960, 640, 1.1);
    const head = heading(root, T.snapshot + 0.1);
    showShot(shot, T.snapshot + 0.1, EV.snapOut, { y: 40 });
    // Framed below the boot menu's title lines from the start, on the snapshot table
    gsap.set(qa(".cam", shot), camAt(shot, 1.45, 532, 390));
    zoom(shot, EV.snapRow - 0.7, 1.7, 532, 380, 1.2);
    tl.to(q(".row-light", shot), { opacity: 1, duration: 0.45, ease: "out" }, EV.snapRow);
    exit([...head, shot], EV.snapOut, { stagger: 0.03 });
  }

  // 7. What it's built on, then the robin lands once more, now with the name
  {
    const root = q("#end"), svg = q("svg", root);
    scene(root, T.end, null);
    glowTo(T.end - 0.6, 960, 520, 1.15);
    const chips = qa(".chip", root);
    enter(chips, EV.chips, { y: 20, scale: 0.96, blur: 8, dur: 0.6, stagger: 0.12 });
    exit(chips, EV.chipsOut, { y: -10, blur: 8, dur: 0.35, stagger: 0.025 });
    const chev = q(".m-chev", svg), cursor = q(".m-cursor", svg), robin = q(".m-robin", svg);
    enter([chev, cursor], EV.lockup - 0.25, { y: 0, blur: 8, dur: 0.5 });
    tl.fromTo(robin, { y: -70, autoAlpha: 0, filter: "blur(10px)" },
      { y: 0, autoAlpha: 1, filter: "blur(0px)", duration: 0.5, ease: "out" }, EV.lockup - 0.1);
    tl.fromTo(robin, { scaleY: 0.95, transformOrigin: "50% 100%" }, { scaleY: 1, duration: 0.3, ease: "out" }, EV.lockup + 0.4);
    const word = q(".word", root);
    tl.fromTo(word, { autoAlpha: 0, x: -24, filter: "blur(12px)", clipPath: "inset(0 100% 0 0)" },
      { autoAlpha: 1, x: 0, filter: "blur(0px)", clipPath: "inset(0 0% 0 0)", duration: 0.9, ease: "out" }, EV.lockup + 0.3);
    enter(qa(".end-meta > *", root), EV.url, { y: 14, blur: 8, dur: 0.7, stagger: 0.12 });
    tl.to(".black", { opacity: 1, duration: DURATION - EV.fadeOut, ease: "inOut" }, EV.fadeOut);
  }

  tl.to({}, { duration: 0 }, DURATION); // the timeline is exactly DURATION long
}

// ── things that move by themselves, computed from t ──
const typed = [];
function ambient(t) {
  if (!REDUCED) gsap.set(".grid", { x: (t * 8) % 24, y: (t * 4) % 24 });

  // Intro cursor: blinks on the beat until the robin lands on it
  const introCursor = q("#intro .m-cursor");
  let on = 0;
  if (t >= EV.cursor && t < EV.land) on = Math.floor((t - EV.cursor) / 0.5) % 2 === 0 ? 1 : 0;
  else if (t >= EV.land) on = 1;
  introCursor.style.opacity = on;

  // Typing in the terminal
  const ranges = [EV.typeCmd, EV.typeLearn];
  typed.forEach((el, i) => {
    const text = el.dataset.text, [a, b] = ranges[i];
    const n = Math.round(Math.max(0, Math.min(1, (t - a) / (b - a))) * text.length);
    if (el.textContent.length !== n) el.textContent = text.slice(0, n);
  });
  // A caret is solid while typing and blinks while waiting; only the last prompt has one
  const blink = (from) => (Math.floor((t - from) / 0.5) % 2 === 0 ? 1 : 0);
  const c1 = q("#c1"), c2 = q("#c2");
  if (t < EV.typeCmd[0]) c1.style.opacity = blink(T.terminal);
  else if (t < EV.hint) c1.style.opacity = 1;
  else c1.style.opacity = 0;
  if (t < EV.typeLearn[0]) c2.style.opacity = blink(EV.hint + 0.3);
  else c2.style.opacity = 1;
}

async function init() {
  mount();
  await document.fonts.load('700 60px "Pretendard"');
  await document.fonts.load('600 60px "Geist"');
  await document.fonts.load('400 30px "Geist Mono"');
  await document.fonts.ready;
  await Promise.all(qa("img").map((img) => img.decode().catch(() => {})));
  typed.push(...qa(".typed"));
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
  document.body.dataset.preview = "";
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
