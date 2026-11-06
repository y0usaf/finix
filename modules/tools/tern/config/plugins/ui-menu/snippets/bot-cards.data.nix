[
  {
    select = ":root:not(#ob) [data-role='omp.bot.you'] .sf-card[data-role^='omp.user']";
    set = [
      ["align-self" "stretch"]
      ["width" "auto"]
      ["max-width" "none"]
      ["margin" "0"]
    ];
  }
  {
    select = ":root:not(#ob) [data-role='omp.bot.you'] .sf-card[data-role^='omp.user'] > .sf-card-body";
    set = [
      ["align-self" "stretch"]
      ["width" "auto"]
      ["max-width" "none"]
      ["margin" "0"]
      ["padding" "0"]
      ["border" "0"]
      ["border-radius" "0"]
      ["background" "none"]
      ["box-shadow" "none"]
    ];
  }
]
