// Tempo, beat grid and section energy of a mono 16-bit WAV, for syncing the video.
// usage: node beats.mjs file.wav from to
import fs from "node:fs";

const [file, fromArg = "0", toArg = "60"] = process.argv.slice(2);
const buf = fs.readFileSync(file);
let p = 12, rate = 22050, data = null;
while (p + 8 <= buf.length) {
  const id = buf.toString("ascii", p, p + 4), size = buf.readUInt32LE(p + 4);
  if (id === "fmt ") rate = buf.readUInt32LE(p + 12);
  if (id === "data") { data = buf.subarray(p + 8, p + 8 + size); break; }
  p += 8 + size + (size & 1);
}
const n = data.length / 2, x = new Float32Array(n);
for (let i = 0; i < n; i++) x[i] = data.readInt16LE(i * 2) / 32768;

// Bands: low (kick/808) by a one-pole low-pass, high (hats/snare) by a high-pass
const lowCut = 1 - Math.exp(-2 * Math.PI * 150 / rate), highCut = 1 - Math.exp(-2 * Math.PI * 3000 / rate);
const low = new Float32Array(n), high = new Float32Array(n);
let l1 = 0, l2 = 0, h = 0;
for (let i = 0; i < n; i++) {
  l1 += lowCut * (x[i] - l1); l2 += lowCut * (l1 - l2); low[i] = l2;
  h += highCut * (x[i] - h); high[i] = x[i] - h;
}
const HOP = 256, frames = Math.floor(n / HOP), fr = rate / HOP;
const eLow = new Float32Array(frames), eHigh = new Float32Array(frames), eAll = new Float32Array(frames);
for (let f = 0; f < frames; f++) {
  let a = 0, b = 0, c = 0;
  for (let i = f * HOP; i < f * HOP + HOP; i++) { a += low[i] ** 2; b += high[i] ** 2; c += x[i] ** 2; }
  eLow[f] = Math.log1p(1000 * a / HOP); eHigh[f] = Math.log1p(1000 * b / HOP); eAll[f] = Math.sqrt(c / HOP);
}
const onset = new Float32Array(frames);
for (let f = 1; f < frames; f++) onset[f] = Math.max(0, eLow[f] - eLow[f - 1]) + 0.6 * Math.max(0, eHigh[f] - eHigh[f - 1]);

const from = Math.floor(Number(fromArg) * fr), to = Math.min(frames, Math.floor(Number(toArg) * fr));
// Tempo by autocorrelation (60–180 BPM)
let best = { bpm: 0, score: -1 };
const scores = [];
for (let bpm = 60; bpm <= 180; bpm += 0.25) {
  const lag = (60 / bpm) * fr;
  let s = 0;
  for (let f = from; f < to - lag - 1; f++) {
    const j = f + lag, j0 = Math.floor(j), w = j - j0;
    s += onset[f] * (onset[j0] * (1 - w) + onset[j0 + 1] * w);
  }
  scores.push([bpm, s]);
  if (s > best.score) best = { bpm, score: s };
}
scores.sort((a, b) => b[1] - a[1]);
console.log("top tempos:", scores.slice(0, 8).map(([b, s]) => `${b}(${(s / best.score).toFixed(2)})`).join(" "));

const bpm = Number(process.env.BPM || best.bpm), period = (60 / bpm) * fr;
// Phase: offset that collects the most onset on the grid
let bestPhase = 0, bestPhaseScore = -1;
for (let ph = 0; ph < period; ph += 0.25) {
  let s = 0;
  for (let f = from + ph; f < to; f += period) s += onset[Math.round(f)] + 0.5 * (onset[Math.round(f) - 1] + onset[Math.round(f) + 1]);
  if (s > bestPhaseScore) { bestPhaseScore = s; bestPhase = ph; }
}
const beats = [];
for (let f = from + bestPhase; f < to; f += period) beats.push(f / fr);
// Downbeat: which of 4 beat positions has the strongest low band
const kickAt = (t) => { const f = Math.round(t * fr); let m = 0; for (let k = -2; k <= 3; k++) m = Math.max(m, eLow[f + k] || 0); return m; };
const pos = [0, 0, 0, 0];
beats.forEach((t, i) => { pos[i % 4] += kickAt(t); });
const down = pos.indexOf(Math.max(...pos));
console.log(`BPM ${bpm.toFixed(2)}, beat ${(60 / bpm).toFixed(4)} s, first beat ${beats[0].toFixed(3)} s, downbeat position ${down} (strengths ${pos.map((v) => v.toFixed(1)).join(" ")})`);
console.log("bars (downbeat time, loudness rms, low, high):");
for (let i = down; i < beats.length; i += 4) {
  const a = Math.round(beats[i] * fr), b = Math.round((beats[i + 4] ?? beats[i] + 4 * 60 / bpm) * fr);
  let r = 0, lo = 0, hi = 0, c = 0;
  for (let f = a; f < Math.min(b, frames); f++) { r += eAll[f]; lo += eLow[f]; hi += eHigh[f]; c++; }
  console.log(`  ${beats[i].toFixed(3)}  rms ${(r / c).toFixed(3)}  low ${(lo / c).toFixed(2)}  high ${(hi / c).toFixed(2)}`);
}
