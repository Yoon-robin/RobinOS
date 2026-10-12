// The soundtrack → out/audio.wav (stereo, 44.1 kHz). Everything is synthesized
// here: an original track, so the video can be shared anywhere.
// Electronic funk, 116 BPM, D minor: punchy kick, tight clap, 16th hats with a
// groove, a funky synth bass with octave jumps, Rhodes-like chord stabs, a pluck
// hook in the second half. Intro (Rhodes and a riser) → drop on beat 8 →
// breakdown on 48 → second drop on 52 → finale on 72.
// Quiet UI sounds from cues.js sit on top: keycaps, typing, Enter, whooshes.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { DURATION, BEAT, BAR, TYPE, SONG, TYPING, PRESSES, ENTERS, WHOOSHES, b } from "./cues.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(HERE, "out", "audio.wav");
const SR = 44100;
const N = Math.ceil(SR * (DURATION + 0.05));
const S16 = BEAT / 4;

const bus = () => [new Float32Array(N), new Float32Array(N)];
const drums = bus(), bass = bus(), keys = bus(), lead = bus(), fx = bus();
const duck = new Float32Array(N).fill(1);

let seed = 116;
const rnd = () => (seed = (seed * 1664525 + 1013904223) >>> 0) / 2147483648 - 1;
function put(target, i, v, pan = 0) {
  if (i < 0 || i >= N) return;
  const a = ((pan + 1) * Math.PI) / 4;
  target[0][i] += v * Math.cos(a) * Math.SQRT2;
  target[1][i] += v * Math.sin(a) * Math.SQRT2;
}
const coef = (fc) => 1 - Math.exp((-2 * Math.PI * fc) / SR);
const mtof = (m) => 440 * Math.pow(2, (m - 69) / 12);

// ── drums ──
function kick(t0, g = 1) {
  const s = Math.round(t0 * SR), n = Math.round(0.38 * SR);
  let ph = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    ph += (2 * Math.PI * (48 + 130 * Math.exp(-t * 38))) / SR;
    const body = Math.sin(ph) * Math.exp(-t * 7.5);
    const click = rnd() * Math.exp(-t * 900) * 0.35;
    put(drums, s + i, Math.tanh((body + click) * 1.4) * g * 0.85);
  }
  for (let i = 0, dn = Math.round(0.3 * SR); i < dn && s + i < N; i++) {
    const t = i / SR;
    duck[s + i] = Math.min(duck[s + i], 1 - 0.45 * Math.min(1, t / 0.004) * Math.exp(-t * 11));
  }
}
function clap(t0, g = 0.32) {
  const s = Math.round(t0 * SR), n = Math.round(0.35 * SR);
  let hp = 0, prev = 0, bp = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const env = t < 0.024 ? Math.exp(-(t % 0.008) * 300) : Math.exp(-(t - 0.024) * 14);
    const x = rnd();
    hp = 0.95 * (hp + x - prev); prev = x;
    bp += 0.35 * (hp - bp);
    put(drums, s + i, bp * env * g * 1.7, (i % 2 ? 0.08 : -0.08));
  }
}
function hat(t0, open, g, pan) {
  const s = Math.round(t0 * SR), n = Math.round((open ? 0.2 : 0.045) * SR);
  let p1 = 0, p2 = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR, x = rnd();
    const h = x - 2 * p1 + p2; p2 = p1; p1 = x;
    put(drums, s + i, h * Math.exp(-t * (open ? 16 : 95)) * g * 0.45, pan);
  }
}
function shaker(t0, g) {
  const s = Math.round(t0 * SR), n = Math.round(0.07 * SR);
  let lp = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR, x = rnd();
    lp += 0.6 * (x - lp);
    put(drums, s + i, (x - lp) * Math.sin(Math.PI * t / 0.07) * g * 0.35, 0.4);
  }
}
function crash(t0, g = 0.11) {
  const s = Math.round(t0 * SR), n = Math.round(2.4 * SR);
  let l1 = 0, l2 = 0, r1 = 0, r2 = 0;
  for (let i = 0; i < n && s + i < N; i++) {
    const t = i / SR, env = Math.exp(-t * 1.7) * g;
    const xl = rnd(), xr = rnd();
    drums[0][s + i] += (xl - 2 * l1 + l2) * env * 0.5; l2 = l1; l1 = xl;
    drums[1][s + i] += (xr - 2 * r1 + r2) * env * 0.5; r2 = r1; r1 = xr;
  }
}
function riser(t0, dur, g = 0.14) {
  const s = Math.round(t0 * SR), n = Math.round(dur * SR);
  let yl = 0, yr = 0;
  for (let i = 0; i < n && s + i < N; i++) {
    const k = i / n, a = coef(250 * Math.pow(7000 / 250, k));
    yl += a * (rnd() - yl); yr += a * (rnd() - yr);
    fx[0][s + i] += yl * 1.3 * k * k * g;
    fx[1][s + i] += yr * 1.3 * k * k * g;
  }
}
function subHit(t0, g = 0.5) {
  const s = Math.round(t0 * SR), n = Math.round(1.6 * SR);
  let ph = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    ph += (2 * Math.PI * (38 + 50 * Math.exp(-t * 4))) / SR;
    put(drums, s + i, Math.sin(ph) * Math.exp(-t * 2.4) * g);
  }
}

// ── harmony: Dm9 – Bbmaj9 – Gm9 – A7sus4 (one bar each) ──
const CHORDS = [
  [50, 57, 60, 64, 65],   // D3 A3 C4 E4 F4   Dm9
  [46, 53, 57, 60, 62],   // Bb2 F3 A3 C4 D4  Bbmaj9
  [43, 50, 53, 57, 58],   // G2 D3 F3 A3 Bb3  Gm9
  [45, 52, 55, 57, 62],   // A2 E3 G3 A3 D4   A7sus4
];
const ROOTS = [38, 34, 31, 33]; // D2 Bb1 G1 A1

// Rhodes-like: a sine with a little FM bell and tremolo
function rhodes(t0, midi, len, g, pan = 0) {
  const f = mtof(midi), s = Math.round(t0 * SR), n = Math.round((len + 0.6) * SR);
  let ph = 0, mph = 0;
  for (let i = 0; i < n && s + i < N; i++) {
    const t = i / SR;
    mph += (2 * Math.PI * f * 14) / SR;
    const idx = 1.6 * Math.exp(-t * 9);
    ph += (2 * Math.PI * f) / SR;
    const env = Math.min(1, t / 0.004) * Math.exp(-t * 2.2) * (t < len ? 1 : Math.exp(-(t - len) * 10));
    const trem = 1 + 0.12 * Math.sin(2 * Math.PI * 5.2 * t);
    put(keys, s + i, Math.sin(ph + idx * Math.sin(mph)) * env * trem * g, pan);
  }
}
function pad(t0, midi, len, g, cutoff = 1800) {
  const f = mtof(midi), s = Math.max(0, Math.round(t0 * SR)), n = Math.round((len + 0.8) * SR);
  for (const [det, pan] of [[0.996, -0.6], [1.004, 0.6]]) {
    let ph = 0, y1 = 0, y2 = 0;
    const a = coef(cutoff);
    for (let i = 0; i < n && s + i < N; i++) {
      const t = i / SR;
      ph = (ph + (f * det) / SR) % 1;
      y1 += a * (2 * ph - 1 - y1); y2 += a * (y1 - y2);
      const env = Math.min(1, t / 0.5) * (t < len ? 1 : Math.exp(-(t - len) * 4));
      put(keys, s + i, y2 * env * g, pan);
    }
  }
}
// Funky synth bass: saw + sub through an envelope filter, short and plucky
function bassNote(t0, midi, dur, g = 0.3) {
  const f = mtof(midi), s = Math.round(t0 * SR), n = Math.round((dur + 0.02) * SR);
  let ph = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    ph = (ph + f / SR) % 1;
    const x = (2 * ph - 1) * 0.55 + Math.sin(2 * Math.PI * ph) * 0.8;
    const a = coef(220 + 1600 * Math.exp(-t * 22));
    y1 += a * (x - y1); y2 += a * (y1 - y2);
    const env = Math.min(1, t / 0.003) * (t < dur ? 1 - 0.3 * Math.min(1, t / dur) : Math.exp(-(t - dur) * 140));
    put(bass, s + i, Math.tanh(y2 * 1.6) * env * g);
  }
}
function pluck(t0, midi, g, pan = 0) {
  const f = mtof(midi), s = Math.round(t0 * SR), n = Math.round(0.5 * SR);
  let ph = 0, y = 0;
  for (let i = 0; i < n && s + i < N; i++) {
    const t = i / SR;
    ph = (ph + f / SR) % 1;
    const x = (4 * Math.abs(ph - 0.5) - 1) * 0.8 + (2 * ph - 1) * 0.25;
    y += coef(900 + 4200 * Math.exp(-t * 9)) * (x - y);
    put(lead, s + i, y * Math.exp(-t * 10) * Math.min(1, t / 0.002) * g, pan);
  }
}

// ── arrangement (bars of 4 beats) ──
const bars = Math.round(SONG.end / 4);
// A funky 16th bass line per bar: [16th, octave offset, length in 16ths]
const BASS = [[0, 0, 3], [3, 0, 1], [6, 12, 1], [8, 0, 2], [10, 0, 1], [11, 12, 1], [14, 7, 2]];
const HOOK = [[0, 74], [3, 77], [6, 76], [8, 72], [10, 74], [14, 69]]; // D5 F5 E5 C5 D5 A4
for (let k = 0; k < bars; k++) {
  const beat = k * 4, t0 = b(beat), ci = k % 4;
  const inBreak = beat >= SONG.breakdown && beat < SONG.drop2;
  const groove = (beat >= SONG.drop1 && beat < SONG.breakdown) || (beat >= SONG.drop2 && beat < SONG.finale);
  const second = beat >= SONG.drop2 && beat < SONG.finale;
  // Rhodes: sustained in the intro and breakdown, offbeat stabs in the grooves
  if (beat < SONG.drop1 || inBreak) {
    CHORDS[ci].forEach((m, j) => rhodes(t0 + j * 0.012, m + 12, BAR * 0.9, inBreak ? 0.06 : 0.085, j % 2 ? 0.3 : -0.3));
    pad(t0, CHORDS[ci][0] + 12, BAR, inBreak ? 0.03 : 0.025, inBreak ? 900 : 1400);
  }
  if (groove) {
    for (const off of [1.5, 2.75, 3.5]) CHORDS[ci].slice(1).forEach((m, j) => rhodes(t0 + b(off) + j * 0.006, m + 12, S16 * 1.6, 0.034, j % 2 ? 0.35 : -0.35));
    pad(t0, CHORDS[ci][0] + 24, BAR, 0.012, 2200);
    for (let q = 0; q < 4; q++) kick(t0 + b(q), q === 0 ? 1 : 0.9);
    if (second) kick(t0 + b(3.5), 0.55);
    clap(t0 + b(1)); clap(t0 + b(3));
    const vel = [0.5, 0.25, 0.85, 0.3];
    for (let q = 0; q < 16; q++) hat(t0 + q * S16 + (q % 2 ? 0.012 : 0), false, 0.1 * vel[q % 4], q % 2 ? 0.3 : -0.2);
    for (let q = 0; q < 4; q++) hat(t0 + b(q + 0.5), true, 0.045, 0.25);
    if (second || beat >= SONG.lift) for (let q = 0; q < 8; q++) shaker(t0 + b(q / 2 + 0.25), 0.18);
    for (const [pos, oct, len] of BASS) bassNote(t0 + pos * S16, ROOTS[ci] + oct, len * S16 - 0.01, 0.3);
    if (second) for (const [pos, m] of HOOK) pluck(t0 + pos * S16, m + (ci === 3 ? -2 : 0), 0.06, pos % 4 ? 0.25 : -0.25);
  }
  // Intro: a pulse of kicks under the last half bar, and a riser into the drop
  if (beat === 4) for (let q = 0; q < 4; q++) hat(t0 + b(q) , false, 0.04 + q * 0.01, 0);
}
riser(b(4), b(4), 0.13);
riser(b(SONG.breakdown), b(4), 0.15);
crash(b(SONG.drop1)); subHit(b(SONG.drop1), 0.5);
crash(b(SONG.drop2)); subHit(b(SONG.drop2), 0.5);
crash(b(SONG.lift), 0.07);
// Finale: one big hit and the tonic ringing out
crash(b(SONG.finale), 0.12); subHit(b(SONG.finale), 0.55); kick(b(SONG.finale), 1);
[50, 57, 60, 64, 69].forEach((m, j) => rhodes(b(SONG.finale) + j * 0.03, m + 12, b(6), 0.05, j % 2 ? 0.3 : -0.3));
pad(b(SONG.finale), 62, b(7), 0.03, 1200);
pluck(b(SONG.finale + 2), 74, 0.05); pluck(b(SONG.finale + 3), 81, 0.04);

// Delay on keys and lead (dotted eighth, ping-pong)
for (const src of [keys, lead]) {
  const D = Math.round(BEAT * 0.75 * SR), fb = src === lead ? 0.42 : 0.28;
  const eL = new Float32Array(N), eR = new Float32Array(N);
  for (let i = D; i < N; i++) {
    eL[i] = (src[1][i - D] + src[0][i - D]) * 0.5 + fb * eR[i - D];
    eR[i] = fb * eL[i - D];
  }
  for (let i = 0; i < N; i++) { src[0][i] += eL[i] * 0.3; src[1][i] += eR[i] * 0.3; }
}

// ── UI sounds ──
function key(t, g, pan = 0) {
  const s = Math.round(t * SR);
  let hp = 0, prev = 0, ph = 0;
  for (let i = 0, n = Math.round(0.05 * SR); i < n; i++) {
    const x = rnd(), tt = i / SR;
    hp = 0.85 * (hp + x - prev); prev = x;
    ph += (2 * Math.PI * (260 - 80 * tt / 0.05)) / SR;
    put(fx, s + i, (hp * Math.exp(-tt * 900) * 0.6 + Math.sin(ph) * Math.exp(-tt * 70) * 0.4) * g, pan);
  }
}
function whoosh(t, g) {
  const s = Math.round(t * SR), n = Math.round(0.45 * SR);
  let l = 0, r = 0;
  for (let i = 0; i < n; i++) {
    const k = i / n, a = coef(300 * Math.pow(10, Math.sin(k * Math.PI) * 0.9));
    l += a * (rnd() - l); r += a * (rnd() - r);
    const env = Math.sin(k * Math.PI) ** 2 * g;
    if (s + i < N) { fx[0][s + i] += l * env; fx[1][s + i] += r * env; }
  }
}
for (const ev of TYPING) for (let k = 0; k < ev.text.length; k++) key(b(ev.at) + k * TYPE, 0.05 + rnd() * 0.015, rnd() * 0.3);
for (const p of PRESSES) p.keys.forEach((_, j) => key(b(p.at) + j * 0.06, 0.11, j ? 0.15 : -0.15));
for (const t of ENTERS) key(b(t), 0.14);
for (const t of WHOOSHES) whoosh(b(t), 0.22);

// ── mix ──
const L = new Float32Array(N), R = new Float32Array(N);
let peak = 0;
for (let i = 0; i < N; i++) {
  const d = duck[i];
  for (const [o, ch] of [[L, 0], [R, 1]]) {
    const v = drums[ch][i] * 0.9 + bass[ch][i] * 0.85 * d + keys[ch][i] * 0.9 * (0.6 + 0.4 * d) + lead[ch][i] * 0.8 * d + fx[ch][i] * 0.8;
    o[i] = Math.tanh(v * 1.05);
  }
  peak = Math.max(peak, Math.abs(L[i]), Math.abs(R[i]));
}
const norm = 0.9 / peak;
const fadeOut = Math.round((DURATION - 1.2) * SR);
const buf = Buffer.alloc(44 + N * 4);
buf.write("RIFF", 0); buf.writeUInt32LE(36 + N * 4, 4); buf.write("WAVE", 8);
buf.write("fmt ", 12); buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(2, 22);
buf.writeUInt32LE(SR, 24); buf.writeUInt32LE(SR * 4, 28); buf.writeUInt16LE(4, 32); buf.writeUInt16LE(16, 34);
buf.write("data", 36); buf.writeUInt32LE(N * 4, 40);
for (let i = 0; i < N; i++) {
  let g = norm * Math.min(1, i / (SR * 0.01));
  if (i > fadeOut) g *= Math.max(0, 1 - (i - fadeOut) / (N - fadeOut));
  buf.writeInt16LE(Math.round(Math.max(-1, Math.min(1, L[i] * g)) * 32767), 44 + i * 4);
  buf.writeInt16LE(Math.round(Math.max(-1, Math.min(1, R[i] * g)) * 32767), 46 + i * 4);
}
fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, buf);
console.log(`소리 ${DURATION.toFixed(2)}초 (직접 만든 곡, ${Math.round(60 / BEAT)}BPM) → ${path.relative(HERE, OUT)}`);
