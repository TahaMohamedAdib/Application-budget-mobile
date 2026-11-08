(() => {
  const storageKey = "vvollet-theme";
  const root = document.documentElement;
  const systemTheme = () => window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";

  const savedTheme = (() => {
    try { return localStorage.getItem(storageKey); } catch { return null; }
  })();

  const applyTheme = (theme) => {
    root.dataset.theme = theme;
    root.style.colorScheme = theme;

    document.querySelectorAll('meta[name="theme-color"]').forEach((meta) => {
      meta.content = theme === "dark" ? "#181a1b" : "#ffffff";
    });

    document.querySelectorAll(".brand picture source").forEach((source) => {
      source.media = theme === "dark" ? "all" : "not all";
    });

    document.querySelectorAll("[data-theme-favicon]").forEach((favicon) => {
      favicon.href = theme === "dark" ? favicon.dataset.darkFavicon : favicon.dataset.lightFavicon;
    });

    document.querySelectorAll("[data-theme-toggle]").forEach((button) => {
      const nextTheme = theme === "dark" ? "light" : "dark";
      button.setAttribute("aria-label", `Switch to ${nextTheme} theme`);
      button.setAttribute("title", `Switch to ${nextTheme} theme`);
      button.setAttribute("aria-pressed", String(theme === "dark"));
    });
  };

  applyTheme(savedTheme === "light" || savedTheme === "dark" ? savedTheme : systemTheme());

  document.addEventListener("DOMContentLoaded", () => {
    applyTheme(root.dataset.theme || systemTheme());

    document.querySelectorAll("[data-theme-toggle]").forEach((button) => {
      button.addEventListener("click", () => {
        const theme = root.dataset.theme === "dark" ? "light" : "dark";
        try { localStorage.setItem(storageKey, theme); } catch { /* Storage may be disabled. */ }
        applyTheme(theme);
      });
    });
  });
})();
