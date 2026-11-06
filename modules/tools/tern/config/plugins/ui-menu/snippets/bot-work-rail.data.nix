[
  {
    select = ":root:not(#b0) [data-role='omp.bot.reply'] [data-role='omp.assistant.note'] .md";
    set = [
      ["font-size" "13px"]
      ["color" "var(--t2)"]
    ];
  }
  {
    select = ":root:not(#b0) [data-role='omp.bot.reply'] [data-role='omp.assistant.note'] .md > :last-child";
    set = [
      ["margin-bottom" "0"]
    ];
  }
  {
    select = ":root:not(#b0) [data-role='omp.bot.reply'] .sf-section[data-role='omp.notice.work'] > .sf-section-head";
    set = [
      ["font-size" "13px"]
      ["color" "var(--t2)"]
    ];
  }
  {
    select = ":root:not(#b0) [data-role='omp.bot.reply'] .sf-section[data-role='omp.notice.work'] > .sf-section-head .sf-t-dim";
    set = [
      ["color" "var(--t4)"]
    ];
  }
  {
    select = ":root:not(#b0) [data-role='omp.bot.reply'] .sf-section[data-role='omp.notice.work'] > .sf-section-body";
    set = [
      ["margin-left" "7px"]
      ["padding-left" "15px"]
      ["box-shadow" "inset 1px 0 0 var(--l2)"]
    ];
  }
]
