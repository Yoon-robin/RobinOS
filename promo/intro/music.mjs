// The soundtrack → out/audio.wav (stereo, 44.1 kHz).
// The music is the track in MUSIC.file from MUSIC.start (Robin's choice, not in
// git). On top go quiet UI sounds from the timeline in cues.js: a key click per
// typed character, Enter, a soft pop when a window opens, and the reboot: the
// music drops out when the screen goes black and a BIOS beep brings the boot menu.
// Without the track file, a click track on the same beat grid stands in, so the
// timing can still be checked.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { DURATION, BEAT, TYPE, TYPE_FAST, MUSIC, EV, TYPING, ENTERS, KEYS, OPENS } from "./cues.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(HERE, "out", "audio.wav");
const SR = 44100;
const N = Math.ceil(SR * DURATION);
const L = new Float32Array(N), R = new Float32Array(N);

function ffmpeg() {
  const bin = process.env.FFMPEG || "ffmpeg";
  const env = path.isAbsolute(bin)
    ? { ...process.env, PATH: [path.dirname(bin), path.join(path.dirname(bin), "..", "lib"), process.env.PATH].join(path.delimiter) }
    : process.env;
  return { bin, env };
}
function readWav(file) {
  const b = fs.readFileSync(file);
  let p = 12, ch = 2, data = null;
  while (p + 8 <= b.length) {
    const id = b.toString("ascii", p, p + 4), size = b.readUInt32LE(p + 4);
    if (id === "fmt ") ch = b.readUInt16LE(p + 10);
    if (id === "data") { data = b.subarray(p + 8, p + 8 + size); break; }
    p += 8 + size + (size & 1);
  }
  const frames = data.length / 2 / ch, l = new Float32Array(frames), r = new Float32Array(frames);
  for (let i = 0; i < frames; i++) {
    l[i] = data.readInt16LE(i * 2 * ch) / 32768;
    r[i] = data.readInt16LE(i * 2 * ch + (ch > 1 ? 2 : 0)) / 32768;
  }
  return [l, r];
}

// ── the music ──
const track = path.join(HERE, MUSIC.file);
let music = null;
if (fs.existsSync(track)) {
  const { bin, env } = ffmpeg();
  const tmp = path.join(os.tmpdir(), `robinos-intro-music-${process.pid}.wav`);
  const r = spawnSync(bin, ["-y", "-loglevel", "error", "-ss", String(MUSIC.start), "-t", String(DURATION + 0.1), "-i", track,
    "-map", "0:a", "-ac", "2", "-ar", String(SR), "-c:a", "pcm_s16le", tmp], { stdio: "inherit", env });
  if (r.status !== 0) throw new Error("음악 파일을 읽지 못했어요 (ffmpeg를 PATH에 두거나 FFMPEG 환경 변수로 알려 주세요)");
  music = readWav(tmp);
  fs.rmSync(tmp, { force: true });
} else {
  console.log(`음악 파일이 없어요(${MUSIC.file}). 같은 박자의 클릭 트랙으로 대신해요`);
  const m = [new Float32Array(N), new Float32Array(N)];
  for (let k = 0; k * BEAT < DURATION; k++) {
    const s = Math.round(k * BEAT * SR), down = k % 4 === 2;
    for (let i = 0; i < SR * 0.06 && s + i < N; i++) {
      const v = Math.sin(2 * Math.PI * (down ? 1500 : 1000) * i / SR) * Math.exp(-i / SR * 60) * 0.3;
      m[0][s + i] += v; m[1][s + i] += v;
    }
  }
  music = m;
}
// Gain: fade in a hair, drop out for the reboot, fade out over the last bar
const gainAt = (t) => {
  let g = Math.min(1, t / 0.02);
  if (t >= EV.powerOff && t < EV.grub) g *= Math.max(0, 1 - (t - EV.powerOff) / 0.03);       // cut
  if (t >= EV.grub && t < EV.grub + 0.05) g *= (t - EV.grub) / 0.05;                          // back in
  if (t > DURATION - MUSIC.fadeOut) g *= Math.max(0, (DURATION - t) / MUSIC.fadeOut);
  return g;
};
for (let i = 0; i < N; i++) {
  const g = gainAt(i / SR) * 0.9;
  L[i] = (music[0][i] ?? 0) * g;
  R[i] = (music[1][i] ?? 0) * g;
}

// ── UI sounds ──
let seed = 20261012;
const rnd = () => (seed = (seed * 1664525 + 1013904223) >>> 0) / 2147483648 - 1;
function put(i, v, pan = 0) {
  if (i < 0 || i >= N) return;
  const a = ((pan + 1) * Math.PI) / 4;
  L[i] += v * Math.cos(a) * Math.SQRT2;
  R[i] += v * Math.sin(a) * Math.SQRT2;
}
function key(t, g, pan = 0) { // a keycap going down: a click and a short body thump
  const s = Math.round(t * SR);
  let hp = 0, prev = 0, ph = 0;
  for (let i = 0, n = Math.round(0.05 * SR); i < n; i++) {
    const x = rnd(), tt = i / SR;
    hp = 0.85 * (hp + x - prev); prev = x;
    ph += (2 * Math.PI * (230 - 70 * tt / 0.05)) / SR;
    put(s + i, (hp * Math.exp(-tt * 900) * 0.7 + Math.sin(ph) * Math.exp(-tt * 70) * 0.45) * g, pan);
  }
}
function pop(t, g) {
  const s = Math.round(t * SR);
  let ph = 0;
  for (let i = 0, n = Math.round(0.1 * SR); i < n; i++) {
    const tt = i / SR;
    ph += (2 * Math.PI * (480 + 600 * Math.exp(-tt * 50))) / SR;
    put(s + i, Math.sin(ph) * Math.exp(-tt * 34) * Math.min(1, tt / 0.002) * g);
  }
}
function beep(t, g) { // a PC speaker's POST beep
  const s = Math.round(t * SR);
  for (let i = 0, n = Math.round(0.16 * SR); i < n; i++) {
    const tt = i / SR, sq = Math.sin(2 * Math.PI * 990 * tt) > 0 ? 1 : -1;
    put(s + i, sq * g * Math.min(1, tt / 0.003) * Math.min(1, (0.16 - tt) / 0.01));
  }
}

for (const ev of TYPING) {
  const step = ev.fast ? TYPE_FAST : TYPE;
  for (let k = 0; k < ev.text.length; k++) key(ev.at + k * step, 0.07 + rnd() * 0.02, rnd() * 0.3);
}
for (let k = 0; k < 5; k++) key(EV.passwordDots + k * TYPE, 0.07);
for (const t of ENTERS) key(t, 0.18);
for (const k of KEYS) k.keys.forEach((_, j) => key(k.at + 0.04 + j * 0.06, 0.12));
for (const t of OPENS) pop(t, 0.05);
beep(EV.grub, 0.06);

// ── out ──
let peak = 0;
for (let i = 0; i < N; i++) peak = Math.max(peak, Math.abs(L[i]), Math.abs(R[i]));
const norm = peak > 0.97 ? 0.97 / peak : 1;
const buf = Buffer.alloc(44 + N * 4);
buf.write("RIFF", 0); buf.writeUInt32LE(36 + N * 4, 4); buf.write("WAVE", 8);
buf.write("fmt ", 12); buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(2, 22);
buf.writeUInt32LE(SR, 24); buf.writeUInt32LE(SR * 4, 28); buf.writeUInt16LE(4, 32); buf.writeUInt16LE(16, 34);
buf.write("data", 36); buf.writeUInt32LE(N * 4, 40);
for (let i = 0; i < N; i++) {
  buf.writeInt16LE(Math.round(Math.max(-1, Math.min(1, L[i] * norm)) * 32767), 44 + i * 4);
  buf.writeInt16LE(Math.round(Math.max(-1, Math.min(1, R[i] * norm)) * 32767), 46 + i * 4);
}
fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, buf);
console.log(`소리 ${DURATION.toFixed(2)}초 · ${music ? "음악" : ""} + 타자·창 소리 → ${path.relative(HERE, OUT)}`);
