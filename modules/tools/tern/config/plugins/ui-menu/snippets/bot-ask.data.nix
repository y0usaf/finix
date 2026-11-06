[
  {
    select = ":root:not(#ob) [data-role='omp.bot.dock'] [data-role='omp.editor.ask']";
    set = [
      ["width" "min(100%, 720px)"]
      ["margin" "8px auto"]
      ["padding" "16px"]
      ["border-radius" "var(--r-card)"]
    ];
  }
  {
    select = ":root:not(#ob) [data-role='omp.bot.dock'] [data-role='omp.ask.question']";
    set = [
      ["font-weight" "600"]
    ];
  }
  {
    select = ":root:not(#ob) [data-role='omp.bot.dock'] [data-role='omp.ask.options']";
    set = [
      ["margin-top" "8px"]
    ];
  }
]
