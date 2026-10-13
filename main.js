// RobinOS landing page: sections rise in as they scroll into view, the nav marks
// the section on screen, and the terminal answers Windows commands with the same
// table the RobinOS terminal uses (hints.json, made by scripts/build-site.py from
// desktop/bash/robinos-hints.sh).
(() => {
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const canObserve = "IntersectionObserver" in window;

  // ---- Entrance ----
  const items = document.querySelectorAll(".reveal");
  if (reduce || !canObserve) {
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

  // ---- Current section in the nav ----
  const links = new Map([...document.querySelectorAll(".nav-links a")].map((a) => [a.hash.slice(1), a]));
  if (canObserve && links.size) {
    const spy = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          links.forEach((a, id) => a.classList.toggle("is-active", id === entry.target.id));
        }
      }
    }, { rootMargin: "-45% 0px -50% 0px" });
    links.forEach((_, id) => {
      const section = document.getElementById(id);
      if (section)
        spy.observe(section);
    });
  }

  // ---- Terminal hints ----
  const form = document.getElementById("hint-form");
  const input = document.getElementById("hint-cmd");
  const out = document.getElementById("hint-out");
  if (!form || !input || !out)
    return;

  // Commands that already are Linux: the page says so instead of "not found"
  const linux = new Set(["ls", "cd", "pwd", "ip", "ps", "top", "htop", "cat", "echo", "clear", "mkdir", "rm",
    "cp", "mv", "grep", "sudo", "pacman", "nano", "vim", "man", "less", "find", "chmod", "chown", "kill",
    "df", "du", "free", "uname", "whoami", "id", "ssh", "ping", "curl", "wget", "systemctl", "journalctl",
    "robinctl", "tar", "touch", "head", "tail", "which", "history", "exit", "ss", "lsblk", "fastfetch"]);

  let hints = null;
  const ready = fetch("hints.json")
    .then((r) => (r.ok ? r.json() : null))
    .then((data) => { hints = data; })
    .catch(() => {});

  const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  const prompt = '<span class="p">robin@robinos ~ &gt;</span> ';

  function answer(typed) {
    // Like the shell: the first word, lower case, without ".exe"
    const word = typed.trim().split(/\s+/)[0] || "";
    const name = word.toLowerCase().replace(/\.exe$/, "");
    if (!name)
      return "";
    const hint = hints && hints[name];
    if (hint) {
      let text = `<b>${esc(word)}</b> 명령은 윈도우용이에요. 리눅스에서는\n`
        + `  <span class="g">${esc(hint.linux)}</span>  <span class="d">${esc(hint.what)}</span>`;
      if (hint.mission)
        text += `\n  <span class="d">직접 해 보기: 학습 미션 ${hint.mission} →</span> robinctl learn show ${hint.mission}`;
      return text;
    }
    if (linux.has(name))
      return `<span class="g">${esc(name)}</span>: 리눅스 명령이에요. RobinOS 터미널에서는 그대로 돼요. 이 페이지에서는 실행하지 않아요.`;
    if (!hints)
      return `<span class="d">명령 표를 불러오지 못했어요. 잠시 뒤에 다시 해 보세요.</span>`;
    return `bash: ${esc(word)}: 명령을 찾을 수 없어요`;
  }

  async function show(typed) {
    await ready;
    const body = answer(typed);
    if (!body)
      return;
    out.innerHTML = prompt + esc(typed.trim()) + "\n" + body;
    if (!reduce) {
      out.classList.remove("fresh");
      void out.offsetWidth;
      out.classList.add("fresh");
    }
  }

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    show(input.value || input.placeholder);
  });

  form.querySelectorAll("[data-cmd]").forEach((button) => {
    button.addEventListener("click", () => {
      input.value = button.dataset.cmd;
      show(button.dataset.cmd);
    });
  });
})();
