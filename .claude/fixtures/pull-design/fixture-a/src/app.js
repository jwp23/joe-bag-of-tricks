// Filter chips: one active at a time; the active chip is announced for screen readers.
document.querySelectorAll(".chip").forEach((chip) => {
  chip.addEventListener("click", () => {
    document.querySelectorAll(".chip").forEach((c) => c.removeAttribute("aria-pressed"));
    chip.setAttribute("aria-pressed", "true");
    document.querySelectorAll(".card").forEach((card) => {
      const filter = chip.dataset.filter;
      card.hidden = filter !== "all" && card.querySelector("h2").textContent.toLowerCase() !== filter;
    });
  });
});
