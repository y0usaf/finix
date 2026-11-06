[
  {
    select = ":root:not(#ob) [data-role='omp.bot.reply'], :root:not(#ob) [data-role='omp.bot.you'], :root:not(#ob) [data-role^='omp.bot.eventbox.']";
    set = [
      ["margin" "-4px 0"]
    ];
  }
  {
    select = ":root:not(#ob) [data-role='omp.bot.more'] + [data-role='omp.bot.reply']";
    set = [
      ["margin-top" "-12px"]
    ];
  }
]
