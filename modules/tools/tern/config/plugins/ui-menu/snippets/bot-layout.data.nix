[
  {
    select = "[data-role^='omp.bot.chat.']";
    set = [
      ["padding" "2px 4px 10px 6px"]
    ];
  }
  {
    select = "[data-role^='omp.bot.hero.']";
    set = [
      ["--p" "5px"]
      ["padding" "48px 0 20px 0"]
    ];
  }
  {
    select = "[data-role^='omp.bot.top.']";
    set = [
      ["--p" "1px"]
      ["padding" "2px 4px 10px 2px"]
      ["box-shadow" "0 1px 0 var(--l1)"]
    ];
  }
  {
    select = "[data-role='omp.bot.floor']";
    set = [
      ["height" "34vh"]
    ];
  }
  {
    select = "[data-role^='omp.bot.'].sf-void";
    set = [
      ["display" "flex !important"]
    ];
  }
  {
    select = "[data-role='omp.bot.none'], [data-role='omp.bot.none'].sf-void, [data-role='omp.bot.more'], [data-role='omp.bot.more'].sf-void";
    set = [
      ["display" "none !important"]
    ];
  }
]
