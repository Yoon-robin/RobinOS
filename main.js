// RobinOS landing page. Sections rise in as they scroll into view, the nav marks
// the section on screen, the desktop in the hero leans toward the pointer, the
// bento borders follow the pointer, the rollback screen follows the step being
// read, and the terminal answers Windows commands with the same table the RobinOS
// terminal uses (hints.json, made by scripts/build-site.py from
// desktop/bash/robinos-hints.sh). No scroll listeners: IntersectionObserver,
// pointer events and CSS scroll timelines only. Reduced motion turns it all off.
(() => {
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const finePointer = window.matchMedia("(hover: hover) and (pointer: fine)").matches;
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
    }, { rootMargin: "0px 0px -10% 0px" });
    items.forEach((el) => seen.observe(el));
  }

  // ---- Current section in the nav ----
  const links = new Map([...document.querySelectorAll(".nav-links a")].map((a) => [a.hash.slice(1), a]));
  if (canObserve && links.size) {
    const spy = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting)
          links.forEach((a, id) => a.classList.toggle("is-active", id === entry.target.id));
      }
    }, { rootMargin: "-45% 0px -50% 0px" });
    links.forEach((_, id) => {
      const section = document.getElementById(id);
      if (section)
        spy.observe(section);
    });
  }

  // ---- Hero: the desktop leans a little toward the pointer ----
  const hero = document.getElementById("top");
  const tilt = document.querySelector(".stage-tilt");
  if (hero && tilt && finePointer && !reduce) {
    let frame = 0;
    hero.addEventListener("pointermove", (event) => {
      if (frame)
        return;
      frame = requestAnimationFrame(() => {
        frame = 0;
        const r = hero.getBoundingClientRect();
        const x = (event.clientX - r.left) / r.width - 0.5;
        const y = (event.clientY - r.top) / r.height - 0.5;
        tilt.style.setProperty("--ry", `${(x * 6).toFixed(2)}deg`);
        tilt.style.setProperty("--rx", `${(-y * 4).toFixed(2)}deg`);
      });
    });
    hero.addEventListener("pointerleave", () => {
      tilt.style.setProperty("--ry", "0deg");
      tilt.style.setProperty("--rx", "0deg");
    });
  }

  // ---- Bento: the light on each tile follows the pointer ----
  const bento = document.getElementById("bento");
  if (bento && finePointer) {
    const tiles = [...bento.querySelectorAll(".tile")];
    let frame = 0;
    bento.addEventListener("pointermove", (event) => {
      if (frame)
        return;
      frame = requestAnimationFrame(() => {
        frame = 0;
        for (const tile of tiles) {
          const r = tile.getBoundingClientRect();
          tile.style.setProperty("--mx", `${event.clientX - r.left}px`);
          tile.style.setProperty("--my", `${event.clientY - r.top}px`);
        }
      });
    });
  }

  // ---- Rollback: the screen follows the step being read ----
  const story = document.getElementById("story");
  if (story && canObserve) {
    const steps = [...story.querySelectorAll(".story-steps li")];
    const shots = [...story.querySelectorAll(".story-frame img")];
    const show = (index) => {
      steps.forEach((li, i) => li.classList.toggle("is-on", i === index));
      shots.forEach((img, i) => img.classList.toggle("is-on", i === index));
    };
    const watch = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting)
          show(steps.indexOf(entry.target));
      }
    }, { rootMargin: "-48% 0px -48% 0px" });
    steps.forEach((li) => watch.observe(li));
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
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  // The lines the shell would print, as HTML
  function answer(typed) {
    // Like the shell: the first word, lower case, without ".exe"
    const word = typed.trim().split(/\s+/)[0] || "";
    const name = word.toLowerCase().replace(/\.exe$/, "");
    if (!name)
      return [];
    const hint = hints && hints[name];
    if (hint) {
      const lines = [
        `<b>${esc(word)}</b> 명령은 윈도우용이에요. 리눅스에서는`,
        `  <span class="g">${esc(hint.linux)}</span>  <span class="d">${esc(hint.what)}</span>`
      ];
      if (hint.mission)
        lines.push(`  <span class="d">직접 해 보기: 학습 미션 ${hint.mission} →</span> robinctl learn show ${hint.mission}`);
      return lines;
    }
    if (linux.has(name))
      return [`<span class="g">${esc(name)}</span>: 리눅스 명령이라 RobinOS 터미널에서는 바로 돼요. 이 페이지에서는 실행하지 않아요.`];
    if (!hints)
      return [`<span class="d">명령 표를 불러오지 못했어요. 잠시 뒤에 다시 해 보세요.</span>`];
    return [`bash: ${esc(word)}: 명령을 찾을 수 없어요`];
  }

  let run = 0;
  async function show(typed) {
    await ready;
    const lines = answer(typed);
    if (!lines.length)
      return;
    const mine = ++run;
    const command = typed.trim();
    if (reduce) {
      out.innerHTML = prompt + esc(command) + "\n" + lines.join("\n");
      return;
    }
    // Type the command, then let the answer's lines appear one after another
    for (let i = 0; i <= command.length; i++) {
      if (mine !== run)
        return;
      out.innerHTML = prompt + esc(command.slice(0, i)) + '<span class="caret"></span>';
      await sleep(i === 0 ? 120 : 34);
    }
    await sleep(160);
    if (mine !== run)
      return;
    out.innerHTML = prompt + esc(command) + "\n"
      + lines.map((line, n) => `<span class="row" style="--n: ${n}">${line}</span>`).join("\n");
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
