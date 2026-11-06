[
  {
    select = ":root:not(#ob) :is([data-role='omp.bot.reply'], [data-role='omp.bot.you']) .md";
    set = [
      ["line-height" "1.45"]
    ];
  }
  {
    select = ":root:not(#ob) :is([data-role='omp.bot.reply'], [data-role='omp.bot.you']) .md > :first-child";
    set = [
      ["margin-top" "0"]
    ];
  }
  {
    select = ":root:not(#ob) :is([data-role='omp.bot.reply'], [data-role='omp.bot.you']) .md > :last-child";
    set = [
      ["margin-bottom" "0"]
    ];
  }
]
