// Timeline of the RobinOS intro video. The picture (main.js) and the sound
// (music.mjs) both read these numbers, so change a time here and nowhere else.
// 120 BPM: a beat is 0.5 s and a bar 2 s. Scenes start on a bar.

export const FPS = 60;
export const BPM = 120;
export const DURATION = 40;

// When each scene starts (seconds)
export const T = {
  intro: 0,      // the robin lands on the prompt cursor, then the wordmark
  keys: 6,       // Windows shortcuts, then the real Alt+Tab screen
  launcher: 12,  // launcher: search by the Windows name (notepad)
  settings: 15,  // quick settings
  terminal: 18,  // a Windows command in the terminal gets the Linux one
  mission: 21.5, // a learning mission in the real terminal
  power: 24,     // one design from power-on: boot menu, login, desktop
  theme: 27,     // dark and light: the whole shell changes together
  snapshot: 30,  // broken by an update? roll back from the boot menu
  end: 34,       // what it's built on, then the logo
};

// Events inside the scenes (seconds)
export const EV = {
  chevron: 0.35,            // the red prompt ">" draws itself
  cursor: 0.85,             // the cursor appears and blinks on the beat
  land: 2.0,                // the robin lands on the cursor (bar 2)
  legs: 2.3,
  word: 3.0,                // the mark steps aside for "RobinOS"
  tagline: 3.6,
  introOut: 5.5,

  keysHead: 6.15,
  combos: [6.9, 7.4, 7.9, 8.4], // one shortcut per beat, each pressed as it lands
  keysShot: 9.4,            // the shortcuts step back for the real Alt+Tab screen
  keysOut: 11.55,

  launcherZoom: 13.0,       // push in to the launcher
  settingsZoom: 15.9,
  settingsOut: 17.55,

  typeCmd: [18.7, 19.25],   // "ipconfig" typed
  hint: 19.45,              // the shell answers with the Linux command
  typeLearn: [20.05, 20.95],// "robinctl learn show 1"
  missionZoom: 22.2,
  missionOut: 23.55,

  tiles: [24.6, 25.1, 25.6],  // boot menu → login → desktop, one per beat
  powerOut: 26.6,
  themeZoom: 27.3,
  themeWipe: 28.1,            // dark wipes to light
  themeOut: 29.55,

  snapRow: 31.1,            // the snapshot row lights up in the boot menu
  snapOut: 33.55,

  chips: 34.3,              // Arch Linux, Hyprland, ...
  chipsOut: 35.9,
  lockup: 36.0,             // the robin lands again, now with the name
  url: 36.8,
  fadeOut: 39.2,
};

export const COMBOS = [
  { keys: ["Win", "E"], label: "파일" },
  { keys: ["Alt", "Tab"], label: "창 전환" },
  { keys: ["Win", "D"], label: "바탕 화면 보기" },
  { keys: ["Win", "V"], label: "클립보드 기록" },
];

export const CHIPS = ["Arch Linux", "Hyprland", "Quickshell", "Btrfs 스냅샷", "한글 입력"];

// Sound effects, synthesized in music.mjs
export const CUES = [
  { t: EV.chevron, sfx: "tick", gain: 0.35 },
  { t: EV.cursor, sfx: "tick", gain: 0.25 },
  { t: EV.land - 0.12, sfx: "whoosh", gain: 0.35 },
  { t: EV.land, sfx: "pop", gain: 0.55 },
  { t: EV.word, sfx: "whoosh", gain: 0.3 },
  { t: EV.tagline, sfx: "chime", gain: 0.4 },
  { t: EV.introOut, sfx: "whoosh", gain: 0.3 },

  ...EV.combos.flatMap((t) => [{ t: t + 0.22, sfx: "key", gain: 0.6 }, { t: t + 0.3, sfx: "key", gain: 0.45 }]),
  { t: EV.keysShot, sfx: "whoosh", gain: 0.45 },
  { t: EV.keysOut, sfx: "whoosh", gain: 0.3 },

  { t: T.launcher + 0.1, sfx: "pop", gain: 0.35 },
  { t: EV.launcherZoom, sfx: "whoosh", gain: 0.3 },
  { t: T.settings + 0.1, sfx: "pop", gain: 0.35 },
  { t: EV.settingsZoom, sfx: "whoosh", gain: 0.3 },

  { t: T.terminal + 0.15, sfx: "pop", gain: 0.35 },
  { t: EV.hint, sfx: "chime", gain: 0.3 }, // typing and Enter come from EV.typeCmd/typeLearn in music.mjs
  { t: T.mission, sfx: "whoosh", gain: 0.4 },

  ...EV.tiles.map((t, i) => ({ t, sfx: "pop", gain: 0.32 + i * 0.04 })),
  { t: T.theme, sfx: "whoosh", gain: 0.4 },
  { t: EV.themeWipe, sfx: "whoosh", gain: 0.35 },

  { t: T.snapshot + 0.1, sfx: "whoosh", gain: 0.35 },
  { t: EV.snapRow, sfx: "chime", gain: 0.4 },

  ...CHIPS.map((_, i) => ({ t: EV.chips + i * 0.12, sfx: "tick", gain: 0.25 })),
  { t: EV.lockup, sfx: "pop", gain: 0.5 },
  { t: EV.url, sfx: "chime", gain: 0.45 },
];
