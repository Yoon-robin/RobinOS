// Preview: starts the local server and opens the page in the browser.
// Click (or Space) plays with sound; add ?t=12 to the address to start at 12 s.
import fs from "node:fs";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
import { serve, HERE } from "./server.mjs";
import { ensureFonts } from "./fonts.mjs";

await ensureFonts();
if (!fs.existsSync(path.join(HERE, "out", "audio.wav"))) spawnSync(process.execPath, [path.join(HERE, "music.mjs")], { stdio: "inherit" });
const { port } = await serve(5179);
const url = `http://127.0.0.1:${port}/`;
console.log(`미리보기: ${url}  (클릭·Space = 재생/멈춤 · ←/→ 2초 이동 · Ctrl+C로 끝)`);
if (process.platform === "win32") spawn("cmd", ["/c", "start", "", url], { stdio: "ignore", detached: true }).unref();
