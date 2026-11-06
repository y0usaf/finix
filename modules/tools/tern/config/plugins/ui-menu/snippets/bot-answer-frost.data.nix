[
  {
    select = ":root:not(#s0):not(#s1) [data-role='omp.bot.reply'] > [data-role^='omp.assistant']";
    set = [
      ["background" "var(--modal-bg)"]
      ["-webkit-backdrop-filter" "var(--frost)"]
      ["backdrop-filter" "var(--frost)"]
      ["box-shadow" "var(--frost-edge)"]
      ["--t1" "var(--frost-ink)"]
      ["color" "var(--frost-ink)"]
    ];
  }
]
