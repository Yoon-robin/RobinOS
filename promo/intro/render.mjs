// Records the video into an mp4.
//   node render.mjs                   → out/robinos-intro.mp4 (1920x1080, 60 fps, with sound)
//   node render.mjs --fps=30 --draft  → out/robinos-intro-draft.mp4 (quick check)
//   node render.mjs --stills=1,5.5,9  → out/stills/*.png at those times (no video)
// Headless Chrome opens index.html?render; for every frame the timeline is frozen
// at that time and captured. It isn't a screen recording, so a slow PC can't drop
// or stutter frames.
// Needs Chrome (or CHROME=<path>) and ffmpeg with libx264 and aac (on PATH or FFMPEG=<path>).
import fs from "node:fs";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
import { serve, HERE } from "./server.mjs";
import { ensureFonts } from "./fonts.mjs";
import { DURATION, FPS as DEFAULT_FPS } from "./cues.js";

const args = Object.fromEntries(process.argv.slice(2).map((a) => { const [k, v] = a.replace(/^--/, "").split("="); return [k, v ?? true]; }));
const FPS = Number(args.fps ?? DEFAULT_FPS);
const DRAFT = !!args.draft;
const STILLS = args.stills ? String(args.stills).split(",").map(Number) : null;
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
  const env = ffmpegEnv(candidate);
  return spawnSync(candidate, ["-version"], { env }).status === 0 ? candidate : null;
}
// Some ffmpeg builds (Remotion's, for one) keep their DLLs in ../lib next to bin/
function ffmpegEnv(ffmpeg) {
  if (!path.isAbsolute(ffmpeg)) return process.env;
  const dirs = [path.dirname(ffmpeg), path.join(path.dirname(ffmpeg), "..", "lib")];
  return { ...process.env, PATH: dirs.join(path.delimiter) + path.delimiter + process.env.PATH };
}

// ── Chrome DevTools protocol ──
async function openPage(url) {
  const profile = fs.mkdtempSync(path.join(process.env.TEMP ?? OUT_DIR, "robinos-intro-chrome-"));
  const port = 9600 + Math.floor(Math.random() * 300);
  const chrome = spawn(CHROME, [
    "--headless=new", "--hide-scrollbars", "--mute-audio", "--no-first-run", "--no-default-browser-check",
    `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`, "--force-device-scale-factor=1",
    "--window-size=1920,1080", "about:blank",
  ], { stdio: "ignore" });
  let target;
  for (let i = 0; i < 50 && !target; i++) {
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
  const close = () => { try { ws.close(); } catch { /* already closed */ } chrome.kill(); setTimeout(() => fs.rmSync(profile, { recursive: true, force: true }), 800); };
  return { send, evaluate, close, logs };
}

const capture = async (page, t, format) => {
  await page.evaluate(`__video.seek(${t.toFixed(6)})`);
  const r = await page.send("Page.captureScreenshot", format === "png"
    ? { format: "png", captureBeyondViewport: false }
    : { format: "jpeg", quality: 90, captureBeyondViewport: false });
  return Buffer.from(r.data, "base64");
};

await ensureFonts();
const FFMPEG = STILLS ? null : findFfmpeg();
if (!STILLS && !FFMPEG) throw new Error("ffmpeg를 찾지 못했어요. PATH에 두거나 FFMPEG 환경 변수에 ffmpeg.exe 경로를 넣어 주세요");

const { srv, port } = await serve(0);
const page = await openPage(`http://127.0.0.1:${port}/index.html?render`);
try {
  if (STILLS) {
    const dir = path.join(OUT_DIR, "stills");
    fs.mkdirSync(dir, { recursive: true });
    for (const t of STILLS) {
      const file = path.join(dir, `t${t.toFixed(2).padStart(5, "0")}.png`);
      fs.writeFileSync(file, await capture(page, t, "png"));
      console.log("찍음", path.relative(HERE, file));
    }
  } else {
    // The sound is made first, every time (the timeline may have changed)
    const music = spawnSync(process.execPath, [path.join(HERE, "music.mjs")], { stdio: "inherit" });
    if (music.status !== 0) throw new Error("소리를 만들지 못했어요");
    const total = Math.round(DURATION * FPS);
    const ff = spawn(FFMPEG, [
      "-y", "-loglevel", "error",
      "-f", "image2pipe", "-framerate", String(FPS), "-c:v", DRAFT ? "mjpeg" : "png", "-i", "-",
      "-i", path.join(OUT_DIR, "audio.wav"),
      "-c:v", "libx264", "-preset", DRAFT ? "veryfast" : "slow", "-crf", DRAFT ? "24" : "16", "-pix_fmt", "yuv420p",
      "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart", OUT,
    ], { stdio: ["pipe", "inherit", "inherit"], env: ffmpegEnv(FFMPEG) });
    // If ffmpeg dies at start (a missing DLL does that silently), stop instead of waiting on the pipe forever
    let ffExit = null;
    ff.on("close", (code) => { ffExit = code; });
    ff.stdin.on("error", () => {});
    const started = Date.now();
    for (let i = 0; i < total; i++) {
      const frame = await capture(page, i / FPS, DRAFT ? "jpeg" : "png");
      if (ffExit !== null) throw new Error(`ffmpeg가 먼저 끝났어요 (코드 ${ffExit}). 위의 ffmpeg 오류를 보세요`);
      if (!ff.stdin.write(frame)) {
        await new Promise((resolve) => {
          const done = () => { ff.stdin.off("drain", done); ff.off("close", done); resolve(); };
          ff.stdin.once("drain", done);
          ff.once("close", done);
        });
      }
      if (i % (FPS * 2) === 0 || i === total - 1) {
        const elapsed = (Date.now() - started) / 1000, eta = (elapsed / (i + 1)) * (total - i - 1);
        process.stdout.write(`\r프레임 ${i + 1}/${total} · ${elapsed.toFixed(0)}초 지남 · 약 ${eta.toFixed(0)}초 남음   `);
      }
    }
    ff.stdin.end();
    const code = ffExit ?? await new Promise((r) => ff.on("close", r));
    if (code !== 0) throw new Error(`ffmpeg 실패 (${code})`);
    console.log(`\n완료: ${path.relative(HERE, OUT)} (${(fs.statSync(OUT).size / 1048576).toFixed(1)}MB)`);
  }
  if (page.logs.length) console.log(page.logs.join("\n"));
} finally {
  page.close();
  srv.close();
}
