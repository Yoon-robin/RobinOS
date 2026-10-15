// Timeline of the RobinOS intro video. The picture (main.js) and the sound
// (music.mjs) both read these numbers; change a time here and nowhere else.
//
// Apple-keynote style: black, one large statement at a time, real RobinOS
// screens floating in 3D with soft light, a big number, a bento grid. The music
// is original (music.mjs): electronic funk, 116 BPM, D minor.
// Times are in beats; b(n) turns them into seconds.

export const FPS = 60;
export const BPM = 116;
export const BEAT = 60 / BPM;
export const BAR = BEAT * 4;
export const TYPE = BEAT / 8; // typing: one character per 32nd note
export const DURATION = 80 * BEAT; // 41.4 s
export const b = (n) => n * BEAT;

// Song map (beats). Drops on 8 and 52, a one-bar breakdown on 48.
export const SONG = { intro: 0, drop1: 8, lift: 24, breakdown: 48, drop2: 52, finale: 72, end: 80 };

// Scenes (beats)
export const S = {
  logo: 0,
  hero: 8,
  screen: 16,   // the screen rises; boot menu → login → desktop inside it
  familiar: 24, // Windows habits
  terminal: 36, // the terminal teaches Linux, 45 missions
  theme: 48,    // breakdown: dark → light
  rollback: 52, // snapshots
  bento: 60,    // everyday screens
  finale: 72,
  end: 80,
};

// Typed text (beats)
export const TYPING = [
  { at: 25.5, target: "search", text: "notepad" },
  { at: 37.5, target: "cmd", text: "ipconfig" },
];
// Keys pressed (beats): visible keycaps and a soft click
export const PRESSES = [
  { at: 25, keys: ["Win", "Space"] },
  { at: 29, keys: ["Alt", "Tab"] },
  { at: 32, keys: ["Win", "."] },
];
// Enter presses (beats)
export const ENTERS = [19.5, 39];
// Big transitions get a soft whoosh (beats, a moment before the cut)
export const WHOOSHES = [7.6, 15.6, 23.6, 35.6, 47.6, 51.6, 59.6, 71.6];
