// Fetches the fonts RobinOS itself uses into fonts/ (not in git):
// Geist and Geist Mono (Latin, numbers, code) and Pretendard (Hangul).
// Same releases and SHA-256 sums as scripts/fetch-fonts.sh. Both are OFL-1.1.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import crypto from "node:crypto";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DIR = path.join(HERE, "fonts");
const RELEASES = [
  {
    url: "https://github.com/vercel/geist-font/releases/download/v1.7.2/geist-font-v1.7.2.zip",
    sha256: "7fc800d2ac6b92844895196e5041aca55d814c15db70c44f79b3b83ab82b04e2",
    // Folders to extract (tar treats [ ] in member names as patterns, so not the files)
    extract: ["geist-font/Geist/webfonts", "geist-font/GeistMono/webfonts"],
    files: { "geist-font/Geist/webfonts/Geist[wght].woff2": "Geist.woff2", "geist-font/GeistMono/webfonts/GeistMono[wght].woff2": "GeistMono.woff2" },
  },
  {
    url: "https://github.com/orioncactus/pretendard/releases/download/v1.3.9/Pretendard-1.3.9.zip",
    sha256: "04be351a74d6bf7d60c480a3087e51d185485d35a52023142af1df19eb8c428a",
    extract: ["web/variable/woff2"],
    files: { "web/variable/woff2/PretendardVariable.woff2": "Pretendard.woff2" },
  },
];

export async function ensureFonts() {
  fs.mkdirSync(DIR, { recursive: true });
  for (const r of RELEASES) {
    if (Object.values(r.files).every((f) => fs.existsSync(path.join(DIR, f)))) continue;
    console.log(`글꼴 받는 중: ${r.url}`);
    const res = await fetch(r.url);
    if (!res.ok) throw new Error(`글꼴을 받지 못했어요 (${res.status}): ${r.url}`);
    const zip = Buffer.from(await res.arrayBuffer());
    const sum = crypto.createHash("sha256").update(zip).digest("hex");
    if (sum !== r.sha256) throw new Error(`체크섬이 달라요: ${r.url}\n  기대: ${r.sha256}\n  실제: ${sum}`);
    const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "robinos-fonts-"));
    try {
      const zipPath = path.join(tmp, "fonts.zip");
      fs.writeFileSync(zipPath, zip);
      const tar = spawnSync("tar", ["-xf", zipPath, "-C", tmp, ...r.extract], { stdio: "inherit" });
      if (tar.status !== 0) throw new Error("zip을 풀지 못했어요 (tar가 zip을 읽을 수 있어야 해요: Windows 10 이상이나 bsdtar)");
      for (const [from, to] of Object.entries(r.files)) fs.copyFileSync(path.join(tmp, from), path.join(DIR, to));
    } finally {
      fs.rmSync(tmp, { recursive: true, force: true });
    }
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  await ensureFonts();
  console.log(`글꼴 준비 끝: ${path.relative(process.cwd(), DIR)}`);
}
