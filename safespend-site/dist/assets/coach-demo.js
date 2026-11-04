(() => {
  const coach = document.querySelector("[data-coach-demo]");
  if (!coach) return;

  const demos = {
    text: {
      label: "Typed question",
      user: "Can I afford a 300 MAD jacket this week?",
      reply:
        "Yes. After the jacket, you would have about 2,070.00 MAD left for the 7 days in this example. That stays within the plan shown here.",
    },
    voice: {
      label: "Voice message",
      transcript: "Add 250 MAD for dinner with friends, paid in cash.",
      reply:
        "I can prepare that expense from Cash. This example moves today's safe-to-spend amount from 295.56 to 281.67 MAD. I'll wait for your confirmation before changing anything.",
    },
  };

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

  function setState(text) {
    state.textContent = text;
  }

  function renderUser(mode) {
    if (mode === "voice") {
      user.classList.add("bubble-voice");
      user.innerHTML = `
        <span class="voice-mark" aria-hidden="true"><i></i><i></i><i></i><i></i></span>
        <span class="voice-copy"><b>Voice note <span class="num">0:08</span></b><span>${demos.voice.transcript}</span></span>
      `;
      return;
    }

    user.classList.remove("bubble-voice");
    user.textContent = demos.text.user;
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
    setState("Coach answered");
    if (announce) announcement.textContent = reply;
  }

  function typeReply(mode, character = 0) {
    const reply = demos[mode].reply;
    coach.classList.remove("is-thinking");
    coach.classList.add("is-typing");
    answer.hidden = false;
    typed.textContent = reply.slice(0, character);

    if (character >= reply.length) {
      showComplete(mode);
      return;
    }

    later(() => typeReply(mode, character + 1), 16);
  }

  function play(mode = activeMode) {
    clearTimers();
    activeMode = mode;
    announcement.textContent = "";
    setSelectedTab(mode);
    renderUser(mode);
    typed.textContent = "";
    answer.hidden = true;

    if (motion.matches) {
      showComplete(mode, false);
      return;
    }

    coach.classList.remove("is-typing");
    coach.classList.add("is-thinking");
    setState("Coach is thinking");
    later(() => {
      setState("Coach is replying");
      typeReply(mode);
    }, 1050);
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
  play();
})();
