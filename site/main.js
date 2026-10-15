// RobinOS landing page. Titles and the terminal rows arrive once as they scroll
// into view (IntersectionObserver), and the tour's arrows page through the
// screens. Everything else moves in CSS. Reduced motion (read live) shows the
// end state at once.
window.robinosReady = true; // index.html shows everything if this never runs
(() => {
  const motionQuery = window.matchMedia("(prefers-reduced-motion: reduce)");
  const canObserve = "IntersectionObserver" in window;

  // ---- Arrivals ----
  const items = document.querySelectorAll(".fade, .cmd-rows");
  const showAll = () => items.forEach((el) => el.classList.add("in"));
  if (motionQuery.matches || !canObserve) {
    showAll();
  } else {
    const seen = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          entry.target.classList.add("in");
          seen.unobserve(entry.target);
        }
      }
    }, { rootMargin: "0px 0px -12% 0px" });
    items.forEach((el) => seen.observe(el));
  }
  motionQuery.addEventListener("change", (event) => {
    if (event.matches)
      showAll();
  });

  // ---- Tour: the arrows move one screen; they grey out at either end ----
  const track = document.getElementById("tour");
  const prev = document.getElementById("tour-prev");
  const next = document.getElementById("tour-next");
  if (!track || !prev || !next)
    return;
  const shots = track.querySelectorAll(".tour-item");
  const step = () => {
    const first = shots[0];
    const gap = parseFloat(getComputedStyle(track).columnGap) || 0;
    return first ? first.getBoundingClientRect().width + gap : track.clientWidth;
  };
  const go = (direction) => track.scrollBy({
    left: direction * step(),
    behavior: motionQuery.matches ? "auto" : "smooth",
  });
  prev.addEventListener("click", () => go(-1));
  next.addEventListener("click", () => go(1));

  if (canObserve && shots.length) {
    const ends = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        const full = entry.intersectionRatio > 0.9;
        if (entry.target === shots[0])
          prev.disabled = full;
        if (entry.target === shots[shots.length - 1])
          next.disabled = full;
      }
    }, { root: track, threshold: [0, 0.9, 1] });
    ends.observe(shots[0]);
    ends.observe(shots[shots.length - 1]);
  }
})();
