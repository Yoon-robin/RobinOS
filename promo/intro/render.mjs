// Records the video into an mp4.
//   node render.mjs                   → out/robinos-intro.mp4 (1920x1080, 60 fps, with sound)
//   node render.mjs --fps=30 --draft  → out/robinos-intro-draft.mp4 (quick check)
//   node render.mjs --stills=1,5.5,9  → out/stills/*.png at those times (no video)
//   options: --workers=N (Chrome windows at once, default: a third of the CPU threads, at most 6),
//            --png (lossless frames instead of JPEG 95), --preset=slow, --crf=16
// Headless Chrome opens index.html?render; for every frame the timeline is frozen
// at that time and captured. It isn't a screen recording, so a slow PC can't drop
// or stutter frames, and the frames can be split between several Chrome windows:
// each one records a stretch into its own segment and ffmpeg joins them.
// Needs Chrome (or CHROME=<path>) and ffmpeg with libx264 and aac (on PATH or FFMPEG=<path>).
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
import { serve, HERE } from "./server.mjs";
import { ensureFonts } from "./fonts.mjs";
import { DURATION, FPS as DEFAULT_FPS } from "./cues.js";

const args = Object.fromEntries(process.argv.slice(2).map((a) => { const [k, v] = a.replace(/^--/, "").split("="); return [k, v ?? true]; }));
const FPS = Number(args.fps ?? DEFAULT_FPS);
const DRAFT = !!args.draft;
const STILLS = args.stills ? String(args.stills).split(",").map(Number) : null;
const WORKERS = Math.max(1, Number(args.workers ?? Math.min(6, Math.floor(os.cpus().length / 3))));
const FRAME = args.png ? "png" : "jpeg";
const PRESET = DRAFT ? "veryfast" : String(args.preset ?? "medium");
const CRF = DRAFT ? "24" : String(args.crf ?? "16");
const OUT_DIR = path.join(HERE, "out");
const OUT = path.join(OUT_DIR, DRAFT ? "robinos-intro-draft.mp4" : "robinos-intro.mp4");
fs.mkdirSync(OUT_DIR, { recursive: true });

const CHROME = [
  process.env.CHROME,
  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe",
  path.join(process.env.LOCALAPPDATA ?? "", "Google\\Chrome\\Application\\chrome.exe"),
  "/usr/bin/google-chrome", "/usr/bin/chromium",
].find((p) => p && fs.existsSync(p));
if (!CHROME) throw new Error("크롬을 찾지 못했어요. CHROME 환경 변수에 chrome.exe 경로를 넣어 주세요");

function findFfmpeg() {
  const candidate = process.env.FFMPEG || "ffmpeg";
  return spawnSync(candidate, ["-version"], { env: ffmpegEnv(candidate) }).status === 0 ? candidate : null;
}
// Some ffmpeg builds (Remotion's, for one) keep their DLLs in ../lib next to bin/
function ffmpegEnv(ffmpeg) {
  if (!path.isAbsolute(ffmpeg)) return process.env;
  const dirs = [path.dirname(ffmpeg), path.join(path.dirname(ffmpeg), "..", "lib")];
  return { ...process.env, PATH: dirs.join(path.delimiter) + path.delimiter + process.env.PATH };
}

// ── Chrome DevTools protocol ──
async function openPage(url, slot) {
  const profile = fs.mkdtempSync(path.join(process.env.TEMP ?? OUT_DIR, "robinos-intro-chrome-"));
  const port = 9500 + (process.pid % 100) * 8 + slot;
  const chrome = spawn(CHROME, [
    "--headless=new", "--hide-scrollbars", "--mute-audio", "--no-first-run", "--no-default-browser-check",
    `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`, "--force-device-scale-factor=1",
    "--window-size=1920,1080", "about:blank",
  ], { stdio: "ignore" });
  let target;
  for (let i = 0; i < 75 && !target; i++) {
    await new Promise((r) => setTimeout(r, 200));
    try { target = await (await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: "PUT" })).json(); } catch { /* not up yet */ }
  }
  if (!target) throw new Error("크롬 디버깅 포트에 붙지 못했어요");
  const ws = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => { ws.addEventListener("open", resolve, { once: true }); ws.addEventListener("error", reject, { once: true }); });
  let id = 0;
  const pending = new Map();
  const logs = [];
  ws.addEventListener("message", (ev) => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) { const { res, rej } = pending.get(m.id); pending.delete(m.id); m.error ? rej(new Error(JSON.stringify(m.error))) : res(m.result); }
    if (m.method === "Runtime.exceptionThrown") logs.push("예외: " + (m.params.exceptionDetails.exception?.description ?? m.params.exceptionDetails.text));
    if (m.method === "Runtime.consoleAPICalled" && m.params.type === "error") logs.push("콘솔: " + m.params.args.map((a) => a.value ?? a.description).join(" "));
  });
  const send = (method, params = {}) => new Promise((res, rej) => { const n = ++id; pending.set(n, { res, rej }); ws.send(JSON.stringify({ id: n, method, params })); });
  const evaluate = async (expression) => {
    const r = await send("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true });
    if (r.exceptionDetails) throw new Error(r.exceptionDetails.exception?.description ?? r.exceptionDetails.text);
    return r.result.value;
  };
  await send("Runtime.enable");
  await send("Page.enable");
  await send("Emulation.setDeviceMetricsOverride", { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false });
  await send("Page.navigate", { url });
  for (let i = 0; i < 150; i++) {
    await new Promise((r) => setTimeout(r, 100));
    if (await evaluate("!!(window.__video && window.__video.ready)").catch(() => false)) break;
    if (i === 149) throw new Error("페이지가 준비되지 않았어요\n" + logs.join("\n"));
  }
  // Closes the connection first and only then ends Chrome. Killing Chrome while the
  // WebSocket was still closing crashed node a moment later (0xC0000409 on Windows,
  // 2026-10-12, once several windows ran at once).
  const close = async () => {
    const timeout = (ms) => new Promise((r) => setTimeout(r, ms));
    if (ws.readyState !== WebSocket.CLOSED) {
      const closed = new Promise((r) => ws.addEventListener("close", r, { once: true }));
      try { ws.close(); } catch { /* already closing */ }
      await Promise.race([closed, timeout(3000)]);
    }
    if (chrome.exitCode === null) {
      const exited = new Promise((r) => chrome.once("exit", r));
      chrome.kill();
      await Promise.race([exited, timeout(5000)]);
    }
    try { fs.rmSync(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 }); } catch { /* a leftover temp folder is harmless */ }
  };
  return { send, evaluate, close, logs };
}

const capture = async (page, t, format) => {
  await page.evaluate(`__video.seek(${t.toFixed(6)})`);
  const r = await page.send("Page.captureScreenshot", format === "png"
    ? { format: "png", captureBeyondViewport: false }
    : { format: "jpeg", quality: DRAFT ? 88 : 95, captureBeyondViewport: false });
  return Buffer.from(r.data, "base64");
};

// One worker: frames [from, to) → its own segment (video only)
async function recordSegment(url, slot, from, to, file, ffmpeg, progress) {
  const page = await openPage(url, slot);
  const ff = spawn(ffmpeg, [
    "-y", "-loglevel", "error",
    "-f", "image2pipe", "-framerate", String(FPS), "-c:v", FRAME === "png" ? "png" : "mjpeg", "-i", "-",
    "-c:v", "libx264", "-preset", PRESET, "-crf", CRF, "-pix_fmt", "yuv420p", "-an", file,
  ], { stdio: ["pipe", "inherit", "inherit"], env: ffmpegEnv(ffmpeg) });
  // If ffmpeg dies at start (a missing DLL does that silently), stop instead of waiting on the pipe forever
  let ffExit = null;
  ff.on("close", (code) => { ffExit = code; });
  ff.stdin.on("error", () => {});
  try {
    for (let i = from; i < to; i++) {
      const frame = await capture(page, i / FPS, FRAME);
      if (ffExit !== null) throw new Error(`ffmpeg가 먼저 끝났어요 (코드 ${ffExit}). 위의 ffmpeg 오류를 보세요`);
      if (!ff.stdin.write(frame)) {
        await new Promise((resolve) => {
          const done = () => { ff.stdin.off("drain", done); ff.off("close", done); resolve(); };
          ff.stdin.once("drain", done);
          ff.once("close", done);
        });
      }
      progress();
    }
    ff.stdin.end();
    const code = ffExit ?? await new Promise((r) => ff.on("close", r));
    if (code !== 0) throw new Error(`ffmpeg 실패 (${code})`);
    return page.logs;
  } finally {
    await page.close();
  }
}

// Runs ffmpeg without blocking (spawnSync while Chrome connections were closing crashed node on Windows)
function run(ffmpeg, argv) {
  return new Promise((resolve) => {
    const p = spawn(ffmpeg, argv, { stdio: "inherit", env: ffmpegEnv(ffmpeg) });
    p.on("close", resolve);
  });
}

await ensureFonts();
const FFMPEG = STILLS ? null : findFfmpeg();
if (!STILLS && !FFMPEG) throw new Error("ffmpeg를 찾지 못했어요. PATH에 두거나 FFMPEG 환경 변수에 ffmpeg.exe 경로를 넣어 주세요");

const { srv, port } = await serve(0);
const url = `http://127.0.0.1:${port}/index.html?render`;
try {
  if (STILLS) {
    const page = await openPage(url, 0);
    try {
      const dir = path.join(OUT_DIR, "stills");
      fs.mkdirSync(dir, { recursive: true });
      for (const t of STILLS) {
        const file = path.join(dir, `t${t.toFixed(2).padStart(5, "0")}.png`);
        fs.writeFileSync(file, await capture(page, t, "png"));
        console.log("찍음", path.relative(HERE, file));
      }
      if (page.logs.length) console.log(page.logs.join("\n"));
    } finally {
      await page.close();
    }
  } else {
    // The sound is made first, every time (the timeline may have changed)
    const music = spawnSync(process.execPath, [path.join(HERE, "music.mjs")], { stdio: "inherit" });
    if (music.status !== 0) throw new Error("소리를 만들지 못했어요");
    const total = Math.round(DURATION * FPS);
    const per = Math.ceil(total / WORKERS);
    const segments = [];
    let done = 0;
    const started = Date.now();
    const report = () => {
      const elapsed = (Date.now() - started) / 1000, eta = done ? (elapsed / done) * (total - done) : 0;
      process.stdout.write(`\r프레임 ${done}/${total} · 크롬 ${WORKERS}개 · ${elapsed.toFixed(0)}초 지남 · 약 ${eta.toFixed(0)}초 남음   `);
    };
    const timer = setInterval(report, 1000);
    try {
      const jobs = [];
      for (let w = 0; w < WORKERS; w++) {
        const from = w * per, to = Math.min(total, from + per);
        if (from >= to) break;
        const file = path.join(OUT_DIR, `segment-${w}.mp4`);
        segments.push(file);
        jobs.push(recordSegment(url, w, from, to, file, FFMPEG, () => { done++; }));
      }
      const logs = (await Promise.all(jobs)).flat();
      report();
      if (logs.length) console.log("\n" + [...new Set(logs)].join("\n"));
    } finally {
      clearInterval(timer);
    }
    // Join the segments (no re-encoding) and add the sound
    const list = path.join(OUT_DIR, "segments.txt");
    // Names relative to the list's own folder (the concat demuxer resolves them there)
    fs.writeFileSync(list, segments.map((f) => `file '${path.basename(f)}'`).join("\n") + "\n");
    const joined = await run(FFMPEG, [
      "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", list, "-i", path.join(OUT_DIR, "audio.wav"),
      "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart", OUT,
    ]);
    if (joined !== 0) throw new Error("조각을 잇지 못했어요");
    // unlinkSync, not rmSync: Node 24's rmSync crashed (0xC0000409) on this path with Hangul in it (바탕화면)
    for (const f of [...segments, list]) { try { fs.unlinkSync(f); } catch { /* already gone */ } }
    console.log(`\n완료: ${path.relative(HERE, OUT)} (${(fs.statSync(OUT).size / 1048576).toFixed(1)}MB, ${((Date.now() - started) / 1000).toFixed(0)}초)`);
  }
} finally {
  srv.close();
}
