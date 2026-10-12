// Timeline of the RobinOS intro video. The picture (main.js) and the sound
// (music.mjs) both read these numbers; change a time here and nowhere else.
//
// The whole video is one RobinOS session: it boots, the desktop works through
// five workspaces (the bar's workspace number is the chapter), and the story is
// typed at a prompt along the bottom. Windows move with RobinOS's own Hyprland
// animation values (desktop/hypr/robinos.lua).
//
// The music is a track Robin chose (not in git, see README "음악"), used from
// MUSIC.start. Its grid, measured 2026-10-12: 114.75 BPM, a beat every 0.5229 s.
// The video starts on a beat two beats before a bar line, so bars begin on
// beats 2, 6, 10, ... The drop is beat 10, one-bar breaks are beats 38 and 70.

export const FPS = 60;
export const BPM = 114.75;
export const BEAT = 60 / BPM;
export const BAR = BEAT * 4;
export const TYPE = BEAT / 8;       // one character per 32nd note
export const TYPE_FAST = BEAT / 16; // the closing address
export const DURATION = 78 * BEAT;  // 40.78 s, to the end of a bar

export const MUSIC = {
  file: "music/track.mp3",  // Robin's file; without it music.mjs makes a click track on the same grid
  start: 10.937,            // seconds into the track ("11초부터 하이라이트")
  fadeOut: 2 * BEAT,
};

const b = (n) => n * BEAT; // time of beat n

// Song map (beats): build 0–10, drop 10, break 38, second part 42, break 70, back 74, end 78
export const SONG = { drop: 10, break1: 38, part2: 42, break2: 70, back: 74 };

export const T = {
  logo: 0,
  boot: b(10),         // on the drop: Enter → boot menu
  login: b(11),
  desktopShot: b(12.5),
  ws1: b(14),          // familiar from the start
  ws2: b(26),          // a little Linux at a time
  ws3: b(38),          // the break: one design, dark and light
  ws4: b(46),          // roll back an update
  ws5: b(58),          // made for every day
  end: b(70),          // the last break: the prompt again
};
export const WORKSPACES = [
  { at: T.ws1, n: 1, title: "런처" },
  { at: T.ws2, n: 2, title: "터미널" },
  { at: T.ws3, n: 3, title: "빠른 설정" },
  { at: T.ws4, n: 4, title: "터미널" },
  { at: T.ws5, n: 5, title: "RobinOS" },
];

export const EV = {
  prompt: b(0.25),      // ">" and the cursor
  land: b(2),           // the robin lands on the cursor, on the first bar line
  name: b(6),           // "RobinOS" typed after the mark
  passwordDots: b(11.5),
  loginEnter: b(12.5),

  launcher: b(15),      // Win+Space
  launcherType: b(16),  // "notepad"
  launcherResult: b(17.25),
  launcherClose: b(18),
  altTab: b(19), altTabOut: b(20.85),
  clipboard: b(21), clipboardOut: b(22.85),
  emoji: b(23), emojiOut: b(25.6),

  term1: b(26.5),       // Win+Enter: a terminal fills the workspace
  ipconfig: b(28),
  hint: b(29),          // Enter: the shell answers with the Linux command
  learnCmd: b(30),
  missionOpen: b(33),   // Enter: the mission window splits the workspace

  ws3Term: b(38.4),
  ws3Launcher: b(39),
  quickSettings: b(40),
  pointer: b(41),       // the pointer goes to the dark mode tile
  themeClick: b(42),    // on the second part's first beat: dark → light
  themeBack: b(45.25),  // light → dark again

  term4: b(46.5),
  updateCmd: b(47),
  updateEnter: b(50),
  powerOff: b(50.5),    // the screen goes black and the music drops out (a reboot)
  grub: b(51),          // a BIOS beep, the boot menu
  grubDown: [b(52), b(52.5), b(53)],
  grubEnter: b(54),     // → the snapshot list

  tiles: [b(59), b(60), b(61), b(62)], // calendar, sound, emoji, quick settings
  allClose: b(68.5),
  barOut: b(69),

  endPrompt: b(70),
  endLand: b(72),
  endName: b(74),       // the music comes back
  url: b(75.5),
  fadeOut: b(76.5),
};

// What is typed where. `target` names an element in index.html.
export const TYPING = [
  { at: EV.name, target: "logo-name", text: "RobinOS" },
  { at: EV.endPrompt, target: "logo-name", text: "" },
  { at: EV.endName, target: "logo-name", text: "RobinOS" },
  { at: T.boot + 0.1, target: "caption", text: "켜는 순간부터 RobinOS예요" },
  { at: T.ws1 + 0.1, target: "caption", text: "윈도우 이름으로 찾아도 돼요" },
  { at: EV.launcherType, target: "launcher-search", text: "notepad" },
  { at: b(18.2), target: "caption", text: "단축키도 대부분 그대로예요" },
  { at: T.ws2 + 0.1, target: "caption", text: "윈도우 명령을 치면 리눅스 명령을 알려 줘요" },
  { at: EV.ipconfig, target: "term1-cmd1", text: "ipconfig" },
  { at: EV.learnCmd, target: "term1-cmd2", text: "robinctl learn show 1" },
  { at: EV.missionOpen + 0.05, target: "caption", text: "미션 45개를 실제 터미널에서 풀어요" },
  { at: T.ws3 + 0.1, target: "caption", text: "다크·라이트를 바꾸면 바와 런처, 터미널이 같이 바뀌어요" },
  { at: T.ws4 + 0.1, target: "caption", text: "업데이트 전후로 스냅샷이 남아요" },
  { at: EV.updateCmd, target: "term4-cmd", text: "sudo robinctl update" },
  { at: EV.grub + 0.1, target: "caption", text: "망가져도 부팅 메뉴에서 되돌려요" },
  { at: T.ws5 + 0.1, target: "caption", text: "직접 만든 화면으로 매일 써요" },
  { at: EV.url, target: "end-url", text: "github.com/Yoon-robin/RobinOS", fast: true },
];
// Enter presses
export const ENTERS = [T.boot, EV.loginEnter, EV.hint, EV.missionOpen, EV.updateEnter, EV.grubEnter];

// Keys shown at the right of the prompt, like a screencast's key display
export const KEYS = [
  { at: EV.launcher, keys: ["Win", "Space"] },
  { at: EV.altTab, keys: ["Alt", "Tab"] },
  { at: EV.clipboard, keys: ["Win", "V"] },
  { at: EV.emoji, keys: ["Win", "."] },
  { at: EV.term1 - 0.1, keys: ["Win", "Enter"] },
  { at: EV.ws3Launcher, keys: ["Win", "Space"] },
  { at: EV.quickSettings, keys: ["Win", "S"] },
  { at: EV.grubDown[0], keys: ["↓", "↓", "↓"] }, // three presses (each one clicks in music.mjs)
];

// Windows and panels that open (a soft pop)
export const OPENS = [EV.launcher + 0.08, EV.altTab + 0.08, EV.clipboard + 0.08, EV.emoji + 0.08, EV.term1, EV.missionOpen + 0.02,
  EV.ws3Term, EV.ws3Launcher + 0.08, EV.quickSettings + 0.08, EV.term4, ...EV.tiles];
