[
  {
    select = ":root:not(#s0):not(#s1) [data-role='omp.bot.you'] .sf-card[data-role^='omp.user'] > .sf-card-body > .sf-md";
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
