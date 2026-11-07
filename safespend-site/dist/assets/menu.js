// Mobile menu: under 720px the header nav collapses behind a toggle button.
(() => {
  const header = document.querySelector(".masthead");
  const button = header && header.querySelector(".menu-toggle");
  const nav = document.getElementById("site-nav");
  if (!button || !nav) return;

  const setOpen = (open) => {
    header.classList.toggle("is-open", open);
    button.setAttribute("aria-expanded", String(open));
    button.setAttribute("aria-label", open ? "Close menu" : "Open menu");
  };

  button.addEventListener("click", () => {
    setOpen(button.getAttribute("aria-expanded") !== "true");
  });

  // Picking a link (including in-page anchors) closes the menu.
  nav.addEventListener("click", (event) => {
    if (event.target.closest("a")) setOpen(false);
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && header.classList.contains("is-open")) {
      setOpen(false);
      button.focus();
    }
  });

  document.addEventListener("click", (event) => {
    if (!header.contains(event.target)) setOpen(false);
  });

  // Back to desktop width: drop the open state so the inline nav is normal.
  window.matchMedia("(min-width: 721px)").addEventListener("change", (event) => {
    if (event.matches) setOpen(false);
  });
})();
