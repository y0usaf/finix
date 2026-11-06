[
  {
    select = ":root:not(#ob) [data-role='omp.bot.you'] .sf-card[data-role^='omp.user']";
    set = [
      ["align-self" "flex-end"]
      ["max-width" "min(80%, 560px)"]
      ["margin" "0 0 0 auto"]
    ];
  }
  {
    select = ":root:not(#ob) [data-role='omp.bot.you'] .sf-card[data-role^='omp.user'] > .sf-card-body";
    set = [
      ["align-items" "flex-end"]
    ];
  }
  {
    select = ":root:not(#ob) [data-role='omp.bot.you'] .sf-card[data-role^='omp.user'] > .sf-card-body > .sf-md";
    set = [
      ["padding" "7px 12px"]
      ["border-radius" "var(--r-card)"]
      ["background" "var(--oz-pink, var(--l2))"]
    ];
  }
]
