// Background music and sound effects → out/audio.wav (stereo, 44.1 kHz).
// Everything is synthesized here: no samples or licenses to track, and every
// hit lands exactly on the times in cues.js.
// Track: 120 BPM in D minor, Dm9 – B♭maj7 – Fmaj7 – Cadd9. Pads alone for the
// intro, the beat comes in with the first feature scene, thins out for the
// snapshot scene and resolves on the logo.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { DURATION, BPM, T, EV, CUES } from "./cues.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(HERE, "out", "audio.wav");

const SR = 44100;
const N = Math.ceil(SR * DURATION);
const BEAT = 60 / BPM;
const BAR = BEAT * 4;
const S16 = BEAT / 4;

const drums = [new Float32Array(N), new Float32Array(N)];
const music = [new Float32Array(N), new Float32Array(N)];
const sfx = [new Float32Array(N), new Float32Array(N)];
const arp = new Float32Array(N);
const duck = new Float32Array(N).fill(1); // the kick presses the rest down a little

let seed = 20261012;
const rnd = () => (seed = (seed * 1664525 + 1013904223) >>> 0) / 2147483648 - 1;
function put(bus, i, v, pan = 0) {
  if (i < 0 || i >= N) return;
  const a = ((pan + 1) * Math.PI) / 4;
  bus[0][i] += v * Math.cos(a) * Math.SQRT2;
  bus[1][i] += v * Math.sin(a) * Math.SQRT2;
}
const coef = (fc) => 1 - Math.exp((-2 * Math.PI * fc) / SR);

// ── drums ──
function kick(t0, g = 1) {
  const s = Math.round(t0 * SR), n = Math.round(0.4 * SR);
  let ph = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    ph += (2 * Math.PI * (44 + 105 * Math.exp(-t * 30))) / SR;
    put(drums, s + i, (Math.sin(ph) * Math.exp(-t * 6.5) + rnd() * Math.exp(-t * 500) * 0.15) * g * 0.9);
  }
  for (let i = 0, dn = Math.round(0.38 * SR); i < dn && s + i < N; i++) {
    const t = i / SR;
    duck[s + i] = Math.min(duck[s + i], 1 - 0.55 * Math.min(1, t / 0.004) * Math.exp(-t * 9));
  }
}
function clap(t0, g = 0.28, pan = 0) {
  const s = Math.round(t0 * SR), n = Math.round(0.26 * SR);
  let hp = 0, prev = 0, lp = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const env = t < 0.03 ? Math.exp(-(t % 0.01) * 260) : Math.exp(-(t - 0.03) * 18);
    const x = rnd();
    hp = 0.94 * (hp + x - prev); prev = x;
    lp += 0.4 * (hp - lp);
    put(drums, s + i, lp * env * g * 1.5, pan);
  }
}
function hat(t0, open, g, pan) {
  const s = Math.round(t0 * SR), n = Math.round((open ? 0.22 : 0.05) * SR);
  let p1 = 0, p2 = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR, x = rnd();
    const h = x - 2 * p1 + p2; p2 = p1; p1 = x;
    put(drums, s + i, h * Math.exp(-t * (open ? 15 : 80)) * g * 0.5, pan);
  }
}
function crash(t0, g = 0.12) {
  const s = Math.round(t0 * SR), n = Math.round(2.6 * SR);
  let l1 = 0, l2 = 0, r1 = 0, r2 = 0;
  for (let i = 0; i < n && s + i < N; i++) {
    const t = i / SR, env = Math.exp(-t * 1.6) * g;
    const xl = rnd(), xr = rnd();
    drums[0][s + i] += (xl - 2 * l1 + l2) * env * 0.5; l2 = l1; l1 = xl;
    drums[1][s + i] += (xr - 2 * r1 + r2) * env * 0.5; r2 = r1; r1 = xr;
  }
}
function subDrop(t0, g = 0.5) {
  const s = Math.round(t0 * SR), n = Math.round(1.4 * SR);
  let ph = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    ph += (2 * Math.PI * (36 + 40 * Math.exp(-t * 3))) / SR;
    put(drums, s + i, Math.sin(ph) * Math.exp(-t * 2.2) * g);
  }
}
function riser(t0, dur, g = 0.16) {
  const s = Math.round(t0 * SR), n = Math.round(dur * SR);
  let yl = 0, yr = 0;
  for (let i = 0; i < n && s + i < N; i++) {
    const k = i / n;
    const a = coef(300 * Math.pow(6000 / 300, k));
    yl += a * (rnd() - yl); yr += a * (rnd() - yr);
    drums[0][s + i] += yl * 1.4 * k * k * g;
    drums[1][s + i] += yr * 1.4 * k * k * g;
  }
}

// ── harmony: Dm9 – B♭maj7 – Fmaj7 – Cadd9 ──
const CHORDS = [
  [146.83, 174.61, 220.0, 261.63, 329.63],
  [116.54, 146.83, 174.61, 220.0, 293.66],
  [130.81, 174.61, 220.0, 261.63, 329.63],
  [130.81, 196.0, 261.63, 293.66, 329.63],
];
const ROOTS = [73.42, 58.27, 87.31, 65.41];

// Pad brightness: opens through the intro, breathes, closes on the ending
function padCutoff(t) {
  if (t < T.keys) return 240 * Math.pow(1500 / 240, t / T.keys);
  if (t < EV.lockup) return 1400 + 380 * Math.sin((2 * Math.PI * t) / 8);
  return 1300 * Math.pow(380 / 1300, Math.min(1, (t - EV.lockup) / (DURATION - EV.lockup)));
}
function padNote(t0, f, len, g) {
  const s = Math.max(0, Math.round(t0 * SR)), n = Math.round((len + 0.5) * SR);
  for (const [det, pan] of [[0.996, -0.55], [1.004, 0.55]]) {
    let ph = 0, y1 = 0, y2 = 0;
    for (let i = 0; i < n && s + i < N; i++) {
      const t = i / SR;
      ph = (ph + (f * det) / SR) % 1;
      const a = coef(padCutoff((s + i) / SR));
      y1 += a * (2 * ph - 1 - y1); y2 += a * (y1 - y2);
      const env = Math.min(1, t / 0.18) * (t < len ? 1 : Math.exp(-(t - len) * 8));
      put(music, s + i, y2 * env * g, pan);
    }
  }
}
function bassNote(t0, f, dur, g = 0.28) {
  const s = Math.round(t0 * SR), n = Math.round((dur + 0.03) * SR), a = coef(480);
  let ph = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    ph = (ph + f / SR) % 1;
    const x = (2 * ph - 1) * 0.6 + Math.sin(2 * Math.PI * ph) * 0.8;
    y1 += a * (x - y1); y2 += a * (y1 - y2);
    const env = Math.min(1, t / 0.006) * (t < dur ? 0.75 + 0.25 * Math.exp(-t * 12) : Math.exp(-(t - dur) * 120));
    put(music, s + i, y2 * env * g);
  }
}
function pluck(t0, f, g) {
  const s = Math.round(t0 * SR), n = Math.round(0.45 * SR);
  let ph = 0, y = 0;
  for (let i = 0; i < n && s + i < N; i++) {
    const t = i / SR;
    ph = (ph + f / SR) % 1;
    const x = (4 * Math.abs(ph - 0.5) - 1) * 0.85 + (2 * ph - 1) * 0.2;
    y += coef(700 + 3400 * Math.exp(-t * 8)) * (x - y);
    arp[s + i] += y * Math.exp(-t * 13) * Math.min(1, t / 0.002) * g;
  }
}

// ── arrangement ──
const bars = Math.round(DURATION / BAR);
for (let b = 0; b < bars; b++) {
  const t0 = b * BAR, ci = b % 4;
  if (t0 < EV.lockup) for (const f of CHORDS[ci]) padNote(t0 - 0.04, f, BAR, t0 < T.keys ? 0.055 : 0.022);

  const beat = t0 >= T.keys && (t0 < T.snapshot || t0 >= T.end) && t0 < EV.lockup;
  if (beat) {
    for (let k = 0; k < 4; k++) kick(t0 + k * BEAT, 0.85);
    clap(t0 + BEAT, 0.26, -0.1);
    clap(t0 + 3 * BEAT, 0.26, 0.1);
    const vel = [0.45, 0.2, 0.8, 0.25];
    for (let k = 0; k < 16; k++) hat(t0 + k * S16, false, 0.1 * vel[k % 4], k % 2 ? 0.35 : -0.25);
    for (let k = 0; k < 4; k++) bassNote(t0 + k * BEAT + BEAT / 2, ROOTS[ci], BEAT / 2 - 0.03);
  }
  // Plucks from the launcher scene on; softer and sparser through the snapshot break
  if (t0 >= T.launcher && t0 < EV.lockup) {
    const tones = CHORDS[ci].slice(1).map((f) => f * 2);
    const pat = [0, 2, 1, 3, 2, 1, 3, 2, 0, 2, 1, 3, 2, 3, 1, 2];
    const brk = t0 >= T.snapshot && t0 < T.end;
    for (let k = 0; k < 16; k++) if (!brk || k % 2 === 0) pluck(t0 + k * S16, tones[pat[k]], (k % 4 === 0 ? 0.07 : 0.045) * (brk ? 0.8 : 1));
  }
  // Intro, second bar: hats come in and build
  if (t0 === 4) for (let k = 0; k < 8; k++) hat(t0 + (k * BEAT) / 2, false, 0.035 + k * 0.007, k % 2 ? 0.3 : -0.3);
}
// The ending: one long Dm9 under the logo, a few plucks that echo away
for (const f of CHORDS[0]) padNote(EV.lockup, f, DURATION - EV.lockup - 1.3, 0.026);
[[EV.lockup, 659.26], [EV.lockup + 0.75, 880], [EV.lockup + 1.5, 587.33], [EV.lockup + 3, 659.26]].forEach(([t, f], i) => pluck(t, f, 0.075 - i * 0.012));
riser(4, 2, 0.16);
riser(T.end - BAR, BAR, 0.18);
crash(T.keys, 0.12); subDrop(T.keys, 0.45); kick(T.keys, 1);
crash(EV.lockup, 0.12); subDrop(EV.lockup, 0.5);

// Plucks → ping-pong delay (dotted eighth)
{
  const D = Math.round(BEAT * 0.75 * SR);
  const eL = new Float32Array(N), eR = new Float32Array(N);
  for (let i = 0; i < N; i++) {
    eL[i] = i >= D ? arp[i - D] + 0.42 * eR[i - D] : 0;
    eR[i] = i >= D ? 0.42 * eL[i - D] : 0;
    music[0][i] += arp[i] * 0.9 + eL[i] * 0.32;
    music[1][i] += arp[i] * 0.9 + eR[i] * 0.32;
  }
}

// ── sound effects ──
const FX = {
  tick(s, g) {
    for (let i = 0, n = Math.round(0.05 * SR); i < n; i++) {
      const t = i / SR;
      put(sfx, s + i, Math.sin(2 * Math.PI * (2200 - 600 * t / 0.05) * t) * Math.exp(-t * 90) * g * 0.6);
    }
  },
  key(s, g, pan = 0) { // a keycap going down: a click and a short body thump
    let hp = 0, prev = 0, ph = 0;
    for (let i = 0, n = Math.round(0.06 * SR); i < n; i++) {
      const t = i / SR, x = rnd();
      hp = 0.85 * (hp + x - prev); prev = x;
      ph += (2 * Math.PI * (210 - 60 * t / 0.06)) / SR;
      put(sfx, s + i, (hp * Math.exp(-t * 900) * 0.7 + Math.sin(ph) * Math.exp(-t * 70) * 0.5) * g, pan);
    }
  },
  whoosh(s, g) {
    const n = Math.round(0.5 * SR);
    let l = 0, r = 0;
    for (let i = 0; i < n; i++) {
      const k = i / n, a = coef(350 * Math.pow(9, Math.sin(k * Math.PI) * 0.9 + k * 0.1));
      l += a * (rnd() - l); r += a * (rnd() - r);
      const env = Math.sin(k * Math.PI) ** 2 * g * 0.9;
      if (s + i < N) { sfx[0][s + i] += l * env; sfx[1][s + i] += r * env; }
    }
  },
  pop(s, g) {
    let ph = 0;
    for (let i = 0, n = Math.round(0.12 * SR); i < n; i++) {
      const t = i / SR;
      ph += (2 * Math.PI * (420 + 520 * Math.exp(-t * 45))) / SR;
      put(sfx, s + i, Math.sin(ph) * Math.exp(-t * 30) * Math.min(1, t / 0.002) * g * 0.7);
    }
  },
  chime(s, g) {
    for (const [f, a, pan] of [[1318.5, 0.5, -0.3], [1975.5, 0.32, 0.3], [2637, 0.14, 0]]) {
      for (let i = 0, n = Math.round(1.6 * SR); i < n; i++) {
        const t = i / SR;
        put(sfx, s + i, Math.sin(2 * Math.PI * f * t) * Math.exp(-t * 3.2) * Math.min(1, t / 0.004) * a * g * 0.5, pan);
      }
    }
  },
};
for (const { t, sfx: name, gain } of CUES) FX[name](Math.round(t * SR), gain);
// Typing: one soft key per character, at the moment it appears on screen (see ambient() in main.js); then Enter
for (const [[a, b], len] of [[EV.typeCmd, "ipconfig".length], [EV.typeLearn, "robinctl learn show 1".length]]) {
  for (let k = 1; k <= len; k++) FX.key(Math.round((a + ((k - 0.5) / len) * (b - a)) * SR), 0.16 + rnd() * 0.04, rnd() * 0.3);
  FX.key(Math.round((b + 0.12) * SR), 0.42);
}

// ── mixdown ──
const L = new Float32Array(N), R = new Float32Array(N);
let peak = 0;
for (let i = 0; i < N; i++) {
  const d = duck[i];
  const l = Math.tanh((drums[0][i] * 0.85 + music[0][i] * 0.9 * d + sfx[0][i] * 0.8) * 1.1);
  const r = Math.tanh((drums[1][i] * 0.85 + music[1][i] * 0.9 * d + sfx[1][i] * 0.8) * 1.1);
  L[i] = l; R[i] = r;
  peak = Math.max(peak, Math.abs(l), Math.abs(r));
}
const norm = 0.89 / peak;
const fadeIn = Math.round(0.01 * SR), fadeOutStart = Math.round(EV.fadeOut * SR);
const buf = Buffer.alloc(44 + N * 4);
buf.write("RIFF", 0); buf.writeUInt32LE(36 + N * 4, 4); buf.write("WAVE", 8);
buf.write("fmt ", 12); buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(2, 22);
buf.writeUInt32LE(SR, 24); buf.writeUInt32LE(SR * 4, 28); buf.writeUInt16LE(4, 32); buf.writeUInt16LE(16, 34);
buf.write("data", 36); buf.writeUInt32LE(N * 4, 40);
for (let i = 0; i < N; i++) {
  let g = norm;
  if (i < fadeIn) g *= i / fadeIn;
  if (i > fadeOutStart) g *= Math.max(0, 1 - (i - fadeOutStart) / (N - fadeOutStart));
  buf.writeInt16LE(Math.round(Math.max(-1, Math.min(1, L[i] * g)) * 32767), 44 + i * 4);
  buf.writeInt16LE(Math.round(Math.max(-1, Math.min(1, R[i] * g)) * 32767), 46 + i * 4);
}
fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, buf);
console.log(`소리 ${DURATION}초 · 효과음 ${CUES.length}개 + 타자 → ${path.relative(HERE, OUT)}`);
