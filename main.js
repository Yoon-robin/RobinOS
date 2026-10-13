// RobinOS landing page: fade sections in as they scroll into view, and type the
// terminal demo (the Windows command hints from desktop/bash/robinos-hints.sh).
(() => {
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  const items = document.querySelectorAll(".reveal");
  if (reduce || !("IntersectionObserver" in window)) {
    items.forEach((el) => el.classList.add("in"));
  } else {
    const seen = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          entry.target.classList.add("in");
          seen.unobserve(entry.target);
        }
      }
    }, { rootMargin: "0px 0px -8% 0px" });
    items.forEach((el) => seen.observe(el));
  }

  // The same hints RobinOS prints for these Windows commands
  const examples = [
    { cmd: "ipconfig", linux: "ip a", what: "IP 주소와 네트워크 장치를 보여 줘요", mission: 6 },
    { cmd: "tasklist", linux: "ps aux", what: "실행 중인 프로세스를 보여 줘요 (실시간으로 보려면 top)", mission: 31 },
    { cmd: "dir", linux: "ls -l", what: "폴더 안의 파일 목록을 보여 줘요", mission: 1 },
    { cmd: "eventvwr", linux: "journalctl -b", what: "이번 부팅의 시스템 기록을 보여 줘요", mission: 35 }
  ];

  const term = document.getElementById("term");
  if (!term || reduce)
    return;

  const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  const prompt = '<span class="p">robin@robinos ~ &gt;</span> ';
  const cursor = '<span class="cursor"></span>';
  const answer = (e) =>
    `<b>${esc(e.cmd)}</b> 명령은 윈도우용이에요. 리눅스에서는\n` +
    `  <span class="g">${esc(e.linux)}</span>  <span class="d">${esc(e.what)}</span>\n` +
    `  <span class="d">직접 해 보기: 학습 미션 ${e.mission} →</span> robinctl learn show ${e.mission}\n`;
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  let started = false;
  async function play() {
    for (let i = 0; ; i = (i + 1) % examples.length) {
      const e = examples[i];
      for (let n = 0; n <= e.cmd.length; n++) {
        term.innerHTML = prompt + esc(e.cmd.slice(0, n)) + cursor;
        await sleep(n === 0 ? 500 : 90);
      }
      await sleep(350);
      term.innerHTML = prompt + esc(e.cmd) + "\n" + answer(e) + prompt + cursor;
      await sleep(4200);
    }
  }

  const watch = new IntersectionObserver((entries) => {
    if (!started && entries.some((x) => x.isIntersecting)) {
      started = true;
      watch.disconnect();
      play();
    }
  });
  watch.observe(term);
})();
