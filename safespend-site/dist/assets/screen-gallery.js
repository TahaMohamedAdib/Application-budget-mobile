(() => {
  const gallery = document.querySelector("[data-screen-gallery]");
  if (!gallery) return;

  const slides = [
    {
      kicker: "First launch",
      title: "Welcome to VVollet",
      description: "A short introduction to the parts of your money life the app helps you keep in view.",
      dark: "assets/screens/demo1.jpeg",
      altDark: "Dark-mode VVollet welcome screen",
    },
    {
      kicker: "First launch",
      title: "See everything at a glance",
      description: "See your accounts, cash, budgets and upcoming commitments in one place.",
      dark: "assets/screens/demo2.jpeg",
      altDark: "Dark-mode VVollet onboarding screen showing a financial overview",
    },
    {
      kicker: "First launch",
      title: "Plan with budgets",
      description: "Set a limit for the things that matter, then let the month stay legible as you spend.",
      dark: "assets/screens/demo3.jpeg",
      altDark: "Dark-mode VVollet onboarding screen about planning with budgets",
    },
    {
      kicker: "First launch",
      title: "Grow your wealth",
      description: "Bring accounts, cash, savings goals and debts into one view of what you own and owe.",
      dark: "assets/screens/demo4.jpeg",
      altDark: "Dark-mode VVollet onboarding screen about growing wealth",
    },
    {
      kicker: "Everyday app",
      title: "Home",
      description: "Your dashboard keeps the current balance and recent activity close, in either app appearance.",
      dark: "assets/screens/home-dark.jpeg",
      light: "assets/screens/home-light.jpeg",
      altDark: "VVollet Home screen in dark appearance with balance chart and recent transactions",
      altLight: "VVollet Home screen in white appearance with balance chart and recent transactions",
    },
    {
      kicker: "Everyday app",
      title: "Quick add",
      description: "Record an expense, income, cash withdrawal or transfer from the action menu.",
      dark: "assets/screens/quick-add-dark.jpeg",
      light: "assets/screens/quick-add-light.jpeg",
      altDark: "VVollet dark Home screen with the quick-add action menu open",
      altLight: "VVollet white Home screen with the quick-add action menu open",
    },
    {
      kicker: "Everyday app",
      title: "Budgets",
      description: "See how each category is tracking before a small expense becomes a month-end surprise.",
      dark: "assets/screens/budgets-dark.jpeg",
      light: "assets/screens/budgets-light.jpeg",
      altDark: "VVollet Budgets screen in dark appearance",
      altLight: "VVollet Budgets screen in white appearance",
    },
    {
      kicker: "Everyday app",
      title: "Wealth",
      description: "Keep your accounts, cash, savings and debts together for a more complete financial picture.",
      dark: "assets/screens/wealth-dark.jpeg",
      light: "assets/screens/wealth-light.jpeg",
      altDark: "VVollet Wealth screen in dark appearance",
      altLight: "VVollet Wealth screen in white appearance",
    },
  ];

  const layers = [...gallery.querySelectorAll("[data-gallery-layer]")];
  const steps = [...document.querySelectorAll("[data-screen-index]")];
  const panel = gallery.querySelector("[data-gallery-panel]");
  const appearance = gallery.querySelector("[data-gallery-appearance]");
  const currentCount = gallery.querySelector("[data-gallery-current]");
  const totalCount = gallery.querySelector("[data-gallery-total]");
  const kicker = gallery.querySelector("[data-gallery-kicker]");
  const title = gallery.querySelector("[data-gallery-title]");
  const description = gallery.querySelector("[data-gallery-description]");
  const previous = gallery.querySelector("[data-gallery-prev]");
  const next = gallery.querySelector("[data-gallery-next]");
  const autoplay = gallery.querySelector("[data-gallery-autoplay]");
  const announcement = gallery.querySelector("[data-gallery-announcement]");
  const themeButtons = [...gallery.querySelectorAll("[data-gallery-theme]")];
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

  let current = 0;
  let activeLayer = 0;
  let theme = "dark";
  let timer;
  let paused = false;
  let engaged = false;

  totalCount.textContent = String(slides.length).padStart(2, "0");

  const sourceFor = (slide) => (theme === "light" && slide.light ? slide.light : slide.dark);
  const altFor = (slide) => (theme === "light" && slide.light ? slide.altLight : slide.altDark);
  const appearanceFor = (slide) => (theme === "light" && slide.light ? "light" : "dark");

  function clearTimer() {
    window.clearTimeout(timer);
  }

  function updateAutoplayButton() {
    const isRunning = !paused && !reducedMotion.matches;
    autoplay.disabled = reducedMotion.matches;
    autoplay.textContent = isRunning ? "Pause" : "Play";
    autoplay.setAttribute("aria-pressed", String(isRunning));
    autoplay.setAttribute("aria-label", isRunning ? "Pause automatic screen tour" : "Play automatic screen tour");
  }

  function schedule() {
    clearTimer();
    if (!paused && !engaged && !reducedMotion.matches) {
      timer = window.setTimeout(() => show(current + 1, { direction: 1 }), 5200);
    }
  }

  function preload(index) {
    const slide = slides[(index + slides.length) % slides.length];
    [slide.dark, slide.light].filter(Boolean).forEach((source) => {
      const image = new Image();
      image.src = source;
    });
  }

  function setText(slide) {
    currentCount.textContent = String(current + 1).padStart(2, "0");
    kicker.textContent = slide.kicker;
    title.textContent = slide.title;
    description.textContent = slide.description;
    appearance.hidden = !slide.light;
    panel.dataset.appearance = appearanceFor(slide);
    steps.forEach((step, index) => step.setAttribute("aria-current", String(index === current)));
    themeButtons.forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.galleryTheme === theme));
    });
  }

  function show(index, options = {}) {
    const { direction = 1, announce = false, immediate = false } = options;
    const nextIndex = (index + slides.length) % slides.length;
    const slide = slides[nextIndex];
    const outgoing = layers[activeLayer];
    const incoming = layers[1 - activeLayer];
    const noMotion = immediate || reducedMotion.matches;

    clearTimer();
    current = nextIndex;
    setText(slide);
    incoming.src = sourceFor(slide);
    incoming.alt = altFor(slide);
    incoming.setAttribute("aria-hidden", "false");

    layers.forEach((layer) => {
      layer.classList.remove("is-exiting-left", "is-exiting-right", "is-entering-left", "is-entering-right");
    });

    if (noMotion) {
      outgoing.classList.remove("is-active");
      outgoing.setAttribute("aria-hidden", "true");
      incoming.classList.add("is-active");
    } else {
      outgoing.classList.remove("is-active");
      outgoing.classList.add(direction > 0 ? "is-exiting-left" : "is-exiting-right");
      incoming.classList.remove("is-active");
      incoming.classList.add(direction > 0 ? "is-entering-right" : "is-entering-left");
      window.requestAnimationFrame(() => {
        incoming.classList.remove("is-entering-right", "is-entering-left");
        incoming.classList.add("is-active");
      });
      window.setTimeout(() => {
        outgoing.setAttribute("aria-hidden", "true");
        outgoing.classList.remove("is-exiting-left", "is-exiting-right");
      }, 420);
    }

    activeLayer = 1 - activeLayer;
    preload(current + 1);
    if (announce) announcement.textContent = `${slide.title}. ${slide.description}`;
    schedule();
  }

  previous.addEventListener("click", () => show(current - 1, { direction: -1, announce: true }));
  next.addEventListener("click", () => show(current + 1, { direction: 1, announce: true }));
  steps.forEach((step) => {
    step.addEventListener("click", () => {
      const index = Number(step.dataset.screenIndex);
      show(index, { direction: index >= current ? 1 : -1, announce: true });
    });
  });
  themeButtons.forEach((button) => {
    button.addEventListener("click", () => {
      theme = button.dataset.galleryTheme;
      show(current, { direction: 1, announce: true });
    });
  });
  autoplay.addEventListener("click", () => {
    paused = !paused;
    updateAutoplayButton();
    schedule();
  });

  gallery.addEventListener("mouseenter", () => {
    engaged = true;
    clearTimer();
  });
  gallery.addEventListener("mouseleave", () => {
    engaged = false;
    schedule();
  });
  gallery.addEventListener("focusin", () => {
    engaged = true;
    clearTimer();
  });
  gallery.addEventListener("focusout", () => {
    window.setTimeout(() => {
      if (!gallery.contains(document.activeElement)) {
        engaged = false;
        schedule();
      }
    });
  });
  reducedMotion.addEventListener("change", () => {
    updateAutoplayButton();
    show(current, { immediate: true });
  });

  updateAutoplayButton();
  show(0, { immediate: true });
})();
