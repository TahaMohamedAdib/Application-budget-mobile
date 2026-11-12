(() => {
  const coach = document.querySelector("[data-coach-demo]");
  if (!coach) return;

  let demos;
  function setDemos() {
    const money = window.VVolletCurrency?.format || ((amount) => `MAD ${Number(amount).toFixed(2)}`);
    demos = {
      text: {
        label: "Typed question",
        user: `Can I afford a ${money(300)} jacket this week?`,
        reply: "Yes. The jacket would be added to your spending and budget history. I can prepare it for your confirmation.",
      },
      voice: {
        label: "Voice message",
        transcript: `Add ${money(250)} for dinner with friends, paid in cash.`,
        reply: `I can prepare that expense from Cash. It will reduce your cash balance by ${money(250)} after you confirm. I'll wait for your confirmation before changing anything.`,
      },
    };
  }
  setDemos();

  const motion = window.matchMedia("(prefers-reduced-motion: reduce)");
  const tabs = [...coach.querySelectorAll("[data-coach-mode]")];
  const stage = coach.querySelector(".coach-stage");
  const state = coach.querySelector("[data-coach-state]");
  const user = coach.querySelector("[data-coach-user]");
  const answer = coach.querySelector("[data-coach-answer]");
  const typed = coach.querySelector("[data-coach-typed]");
  const announcement = coach.querySelector("[data-coach-announcement]");
  const replay = coach.querySelector("[data-coach-replay]");
  let timers = [];
  let activeMode = "text";

  function clearTimers() {
    timers.forEach((timer) => window.clearTimeout(timer));
    timers = [];
  }

  function later(callback, delay) {
    timers.push(window.setTimeout(callback, delay));
  }

  function setState(text, announce = true) {
    state.setAttribute("aria-live", announce ? "polite" : "off");
    state.textContent = text;
  }

  function promptFor(mode) {
    return mode === "voice" ? demos.voice.transcript : demos.text.user;
  }

  function renderUser(mode, character) {
    const prompt = promptFor(mode);
    const visiblePrompt = Number.isInteger(character) ? prompt.slice(0, character) : prompt;
    user.hidden = false;

    if (mode === "voice") {
      user.classList.add("bubble-voice");
      user.innerHTML = `
        <span class="voice-mark" aria-hidden="true"><i></i><i></i><i></i><i></i></span>
        <span class="voice-copy"><b>Voice note <span class="num">0:08</span></b><span data-coach-transcript></span></span>
      `;
      user.querySelector("[data-coach-transcript]").textContent = visiblePrompt;
      return;
    }

    user.classList.remove("bubble-voice");
    user.textContent = visiblePrompt;
  }

  function setSelectedTab(mode) {
    tabs.forEach((tab) => {
      const isActive = tab.dataset.coachMode === mode;
      tab.setAttribute("aria-selected", String(isActive));
      tab.tabIndex = isActive ? 0 : -1;
      if (isActive) stage.setAttribute("aria-labelledby", tab.id);
    });
  }

  function showComplete(mode, announce = true) {
    const reply = demos[mode].reply;
    coach.classList.remove("is-thinking", "is-typing");
    answer.hidden = false;
    typed.textContent = reply;
    setState("Coach answered", announce);
    if (announce) announcement.textContent = reply;
    if (!motion.matches) later(() => play(mode, false), 2000);
  }

  function typeReply(mode, character = 0, announce = true) {
    const reply = demos[mode].reply;
    coach.classList.remove("is-thinking");
    coach.classList.add("is-typing");
    answer.hidden = false;
    typed.textContent = reply.slice(0, character);

    if (character >= reply.length) {
      showComplete(mode, announce);
      return;
    }

    later(() => typeReply(mode, character + 1, announce), 16);
  }

  function startReply(mode, announce) {
    coach.classList.remove("is-writing", "is-typing");
    coach.classList.add("is-thinking");
    setState("Coach is thinking", announce);
    later(() => {
      setState("Coach is replying", announce);
      typeReply(mode, 0, announce);
    }, 1050);
  }

  function typePrompt(mode, character = 0, announce = true) {
    const prompt = promptFor(mode);
    coach.classList.add("is-writing");
    renderUser(mode, character);

    if (character >= prompt.length) {
      coach.classList.remove("is-writing");
      later(() => startReply(mode, announce), 260);
      return;
    }

    later(() => typePrompt(mode, character + 1, announce), mode === "voice" ? 12 : 16);
  }

  function play(mode = activeMode, announce = true) {
    clearTimers();
    activeMode = mode;
    announcement.textContent = "";
    setSelectedTab(mode);
    user.hidden = true;
    typed.textContent = "";
    answer.hidden = true;
    coach.classList.remove("is-thinking", "is-typing", "is-writing");

    if (motion.matches) {
      renderUser(mode);
      showComplete(mode, false);
      return;
    }

    setState(mode === "voice" ? "User is recording" : "User is typing", announce);
    typePrompt(mode, 0, announce);
  }

  tabs.forEach((tab) => {
    tab.addEventListener("click", () => play(tab.dataset.coachMode));
    tab.addEventListener("keydown", (event) => {
      if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
      event.preventDefault();
      const index = tabs.indexOf(tab);
      const nextIndex = event.key === 'ArrowLeft' ? (index + tabs.length - 1) % tabs.length
        : event.key === 'ArrowRight' ? (index + 1) % tabs.length
        : event.key === 'Home' ? 0 : tabs.length - 1;
      tabs[nextIndex].focus();
      play(tabs[nextIndex].dataset.coachMode);
    });
  });

  replay.addEventListener("click", () => play());
  motion.addEventListener?.("change", () => play());
  window.addEventListener("vvollet:currencychange", () => {
    setDemos();
    play(activeMode, false);
  });
  play();
})();
