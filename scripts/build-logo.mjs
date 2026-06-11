// RobinOS 로고 빌드 스크립트
// 글리프를 벡터 패스(아웃라인)로 변환 → 폰트 없이도 어디서든 동일하게 보이는
// SVG 생성 → sharp 로 여러 크기 PNG 추출.
//
// 워드마크(Robin+OS): text-to-svg (내부 opentype 0.11, 안정적) 로 생성.
// 마크의 R: opentype.js v2 의 getPath('R',0,0) (단일 글자·x=0 에서 정상) 로 생성.
//   ※ opentype v2 의 다중 글자/오프셋 getPath 는 O·S 등에서 NaN 버그가 있어 회피함.
//
// 실행:  node scripts/build-logo.mjs   (scripts/Poppins-Bold.ttf 필요)

import TextToSVG from "text-to-svg";
import opentype from "opentype.js";
import sharp from "sharp";
import { writeFileSync, readFileSync, mkdirSync } from "fs";

const FONT = "scripts/Poppins-Bold.ttf";
const OUT = "public/brand";
const PNG = "public/brand/png";
mkdirSync(PNG, { recursive: true });

const round = (n) => Math.round(n * 100) / 100;
const assertClean = (d, who) => {
  if (d.includes("NaN")) throw new Error(`NaN in ${who}`);
  return d;
};

// path d 문자열에서 좌표(x,y 쌍)를 읽어 바운딩박스 계산 (폰트 아웃라인엔 호 명령이
// 없고 모든 명령이 좌표쌍이라 number 를 순서대로 (x,y) 로 묶으면 됨)
function bboxOfD(d) {
  const nums = d.match(/-?\d+(?:\.\d+)?/g).map(Number);
  let x1 = Infinity, y1 = Infinity, x2 = -Infinity, y2 = -Infinity;
  for (let i = 0; i + 1 < nums.length; i += 2) {
    const x = nums[i], y = nums[i + 1];
    if (x < x1) x1 = x;
    if (x > x2) x2 = x;
    if (y < y1) y1 = y;
    if (y > y2) y2 = y;
  }
  return { x1, y1, x2, y2 };
}

const GRAD = `<linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#6366f1"/>
      <stop offset="0.5" stop-color="#a855f7"/>
      <stop offset="1" stop-color="#ec4899"/>
    </linearGradient>`;

// ---------- 1) 워드마크 (Robin + 그라데이션 OS) ----------
const t2s = TextToSVG.loadSync(FONT);
const FS = 100;
const base = { fontSize: FS, anchor: "left baseline", kerning: true };

const dRobin = assertClean(t2s.getD("Robin", { x: 0, y: 0, ...base }), "Robin");
const wRobin = t2s.getMetrics("Robin", { x: 0, y: 0, ...base }).width;
const dOS = assertClean(t2s.getD("OS", { x: wRobin, y: 0, ...base }), "OS");

const bbAll = [bboxOfD(dRobin), bboxOfD(dOS)].reduce((a, b) => ({
  x1: Math.min(a.x1, b.x1), y1: Math.min(a.y1, b.y1),
  x2: Math.max(a.x2, b.x2), y2: Math.max(a.y2, b.y2),
}));

const PAD = 8;
const W = round(bbAll.x2 - bbAll.x1 + PAD * 2);
const H = round(bbAll.y2 - bbAll.y1 + PAD * 2);
const tx = round(-bbAll.x1 + PAD);
const ty = round(-bbAll.y1 + PAD);

const wordmark = (robinFill) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}" role="img" aria-label="RobinOS">
  <defs>${GRAD}</defs>
  <g transform="translate(${tx},${ty})">
    <path d="${dRobin}" fill="${robinFill}"/>
    <path d="${dOS}" fill="url(#g)"/>
  </g>
</svg>
`;

writeFileSync(`${OUT}/logo-wordmark.svg`, wordmark("currentColor"));
writeFileSync(`${OUT}/logo-wordmark-light.svg`, wordmark("#ffffff"));
writeFileSync(`${OUT}/logo-wordmark-dark.svg`, wordmark("#0f1226"));

// ---------- 2) 마크 (정사각 앱 아이콘: 그라데이션 사각형 + 흰 R) ----------
const ttf = readFileSync(FONT);
const font = opentype.parse(ttf.buffer.slice(ttf.byteOffset, ttf.byteOffset + ttf.byteLength));
const FSR = 92;
const pR = font.getPath("R", 0, 0, FSR); // 단일 글자·x=0 → NaN 회피
const dR = assertClean(pR.toPathData(2), "R");
const b = pR.getBoundingBox();
const rW = b.x2 - b.x1, rH = b.y2 - b.y1;
const rdx = round(60 - (b.x1 + rW / 2));
const rdy = round(60 - (b.y1 + rH / 2));

const mark = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" width="120" height="120" role="img" aria-label="RobinOS">
  <defs>${GRAD}</defs>
  <rect x="6" y="6" width="108" height="108" rx="30" fill="url(#g)"/>
  <path d="${dR}" transform="translate(${rdx},${rdy})" fill="#ffffff"/>
</svg>
`;
writeFileSync(`${OUT}/logo-mark.svg`, mark);

// ---------- 3) PNG 추출 ----------
const markBuf = Buffer.from(mark);
const wmDark = Buffer.from(wordmark("#0f1226"));
const wmLight = Buffer.from(wordmark("#ffffff"));

for (const s of [16, 32, 48, 64, 128, 256, 512]) {
  await sharp(markBuf, { density: 700 }).resize(s, s).png().toFile(`${PNG}/mark-${s}.png`);
}
await sharp(markBuf, { density: 700 }).resize(48, 48).png().toFile(`${PNG}/favicon.png`);

for (const w of [256, 512, 1024]) {
  await sharp(wmDark, { density: 400 }).resize({ width: w }).png().toFile(`${PNG}/wordmark-${w}.png`);
}
await sharp(wmLight, { density: 400 }).resize({ width: 512 }).png().toFile(`${PNG}/wordmark-light-512.png`);

console.log(`wordmark viewBox: ${W} x ${H}  (Robin width ${round(wRobin)})`);
console.log(`R bbox: ${round(rW)} x ${round(rH)}  translate(${rdx}, ${rdy})`);
console.log("DONE — no NaN");
