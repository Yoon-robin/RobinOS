// RobinOS landing page. Cards arrive once as they scroll into view, and the tab bar
// under the header marks the section on screen. Reduced motion
// (read live) shows everything at once; without the script index.html shows it all.
window.robinosReady = true;
(() => {
  const motionQuery = window.matchMedia("(prefers-reduced-motion: reduce)");
  const canObserve = "IntersectionObserver" in window;

  // ---- Arrivals ----
  const items = document.querySelectorAll(".arrive");
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
    }, { rootMargin: "0px 0px -8% 0px" });
    items.forEach((el) => seen.observe(el));
  }
  motionQuery.addEventListener("change", (event) => {
    if (event.matches)
      showAll();
  });

  // ---- The tab bar follows the section in view ----
  if (!canObserve)
    return;
  const links = new Map();
  document.querySelectorAll('.tabs a[href^="#"]').forEach((a) => links.set(a.getAttribute("href").slice(1), a));
  const mark = (id) => links.forEach((a, key) => {
    if (key === id)
      a.setAttribute("aria-current", "true");
    else
      a.removeAttribute("aria-current");
  });
  const spy = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting)
        mark(entry.target.classList.contains("hero") ? "main" : entry.target.id);
    }
  }, { rootMargin: "-40% 0px -55% 0px" });
  links.forEach((_, id) => {
    const section = id === "main" ? document.querySelector(".hero") : document.getElementById(id);
    if (section)
      spy.observe(section);
  });
})();
