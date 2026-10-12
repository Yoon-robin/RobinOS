.pragma library

// Windows programs people bring along (T-159): what a downloaded installer's file
// name looks like, and what to use on RobinOS instead. WindowsApp.qml shows it when
// an .exe or .msi is opened. Each choice is one of:
//   { app: "<desktop id>" }         an app RobinOS already has
//   { flathub: "<app id>" }         an app from the app store (GNOME Software)
//   { web: "<url>" }                a web version in the browser
const known = [
    { match: ["kakaotalk", "kakao"], name: "카카오톡",
      note: "리눅스용 카카오톡은 없어요. 휴대폰 카카오톡을 쓰거나, Bottles로 윈도우판을 실행해 볼 수 있어요(안 될 때도 있어요).",
      choices: [{ flathub: "com.usebottles.bottles", title: "Bottles 설치하기", desc: "윈도우 프로그램 실행기" }] },
    { match: ["chromesetup", "chrome"], name: "Chrome",
      note: "Firefox가 이미 있어요. Chrome이 꼭 필요하면 앱 스토어에서 받아요.",
      choices: [{ app: "firefox", title: "Firefox 열기", desc: "이미 설치된 브라우저" },
                { flathub: "com.google.Chrome", title: "Chrome 설치하기", desc: "앱 스토어(Flathub)" }] },
    { match: ["whale"], name: "네이버 웨일",
      note: "Firefox가 이미 있어요.",
      choices: [{ app: "firefox", title: "Firefox 열기", desc: "이미 설치된 브라우저" }] },
    { match: ["hwp", "hoffice", "hancom", "hanword"], name: "한글(한컴오피스)",
      note: "한글 문서(.hwp)는 한컴독스 웹에서 열고 고칠 수 있어요. LibreOffice Writer도 간단한 .hwp는 열어요.",
      choices: [{ web: "https://www.hancomdocs.com", title: "한컴독스 열기", desc: "웹 브라우저에서" },
                { app: "libreoffice-writer", title: "LibreOffice Writer 열기", desc: "이미 설치된 문서 앱" }] },
    { match: ["officesetup", "office", "excel", "powerpoint", "o365"], name: "Microsoft Office",
      note: "LibreOffice가 이미 있어요. 워드·엑셀·파워포인트 파일을 열고 저장할 수 있어요. 웹 버전 Office도 브라우저에서 돼요.",
      choices: [{ app: "libreoffice-writer", title: "LibreOffice 열기", desc: "이미 설치된 오피스" },
                { web: "https://www.office.com", title: "웹 Office 열기", desc: "Microsoft 계정으로" }] },
    { match: ["bandizip", "winrar", "alzip", "7z"], name: "압축 프로그램",
      note: "압축 풀기는 이미 돼요. 파일 탐색기에서 압축 파일을 오른쪽 클릭하고 \"압축 풀기\"를 눌러요.",
      choices: [{ app: "org.gnome.FileRoller", title: "압축 관리자 열기", desc: "zip, 7z, rar, tar" }] },
    { match: ["gomplayer", "potplayer", "kmplayer", "vlc"], name: "동영상 플레이어",
      note: "동영상 재생 앱이 이미 있어요. 더 많은 형식이 필요하면 VLC를 받아요.",
      choices: [{ app: "org.gnome.Showtime", title: "동영상 재생 앱 열기", desc: "이미 설치된 플레이어" },
                { flathub: "org.videolan.VLC", title: "VLC 설치하기", desc: "앱 스토어(Flathub)" }] },
    { match: ["discord"], name: "Discord",
      choices: [{ flathub: "com.discordapp.Discord", title: "Discord 설치하기", desc: "앱 스토어(Flathub)" }] },
    { match: ["steam"], name: "Steam",
      choices: [{ flathub: "com.valvesoftware.Steam", title: "Steam 설치하기", desc: "앱 스토어(Flathub). 윈도우 게임도 대부분 돼요(Proton)" }] },
    { match: ["vscode", "vscodeusersetup", "visualstudiocode"], name: "Visual Studio Code",
      choices: [{ flathub: "com.visualstudio.code", title: "VS Code 설치하기", desc: "앱 스토어(Flathub)" }] },
    { match: ["zoom"], name: "Zoom",
      choices: [{ flathub: "us.zoom.Zoom", title: "Zoom 설치하기", desc: "앱 스토어(Flathub)" }] },
    { match: ["spotify"], name: "Spotify",
      choices: [{ flathub: "com.spotify.Client", title: "Spotify 설치하기", desc: "앱 스토어(Flathub)" }] },
    { match: ["telegram"], name: "Telegram",
      choices: [{ flathub: "org.telegram.desktop", title: "Telegram 설치하기", desc: "앱 스토어(Flathub)" }] },
    { match: ["obs-studio", "obsstudio"], name: "OBS Studio",
      choices: [{ flathub: "com.obsproject.Studio", title: "OBS Studio 설치하기", desc: "앱 스토어(Flathub)" }] },
    { match: ["npp", "notepad"], name: "메모장 프로그램",
      note: "텍스트 편집기가 이미 있어요.",
      choices: [{ app: "org.gnome.TextEditor", title: "텍스트 편집기 열기", desc: "이미 설치된 메모장" }] },
    { match: ["python"], name: "Python",
      note: "Python은 이미 설치돼 있어요. 터미널에서 python을 입력해요.",
      choices: [{ app: "org.gnome.Ptyxis", title: "터미널 열기", desc: "python 입력" }] },
    { match: ["git-", "gitforwindows"], name: "Git",
      note: "git은 이미 설치돼 있어요. 터미널에서 git을 입력해요.",
      choices: [{ app: "org.gnome.Ptyxis", title: "터미널 열기", desc: "git 입력" }] }
];

// Unknown programs: Bottles runs many Windows programs, not all
const fallback = [{ flathub: "com.usebottles.bottles", title: "Bottles 설치하기", desc: "윈도우 프로그램 실행기 (되는 프로그램도, 안 되는 프로그램도 있어요)" }];

// "KakaoTalk_Setup (1).exe" -> "kakaotalksetup1"
function squash(name) {
    return name.toLowerCase().replace(/\.(exe|msi|lnk)$/, "").replace(/[^a-z0-9]/g, "");
}

// The known program for a file name, or null
function find(fileName) {
    const raw = fileName.toLowerCase();
    const squashed = squash(fileName);
    for (const program of known) {
        for (const word of program.match) {
            // "Kakao Talk Setup.exe" still finds "kakaotalk"; short words only match
            // as written, or "git" would find "digital"
            const bare = word.replace(/[^a-z0-9]/g, "");
            if (raw.indexOf(word) !== -1 || (bare.length >= 5 && squashed.indexOf(bare) !== -1))
                return program;
        }
    }
    return null;
}
