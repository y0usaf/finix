[
  {
    select = "[data-role='omp.bot.event.row']";
    set = [
      ["align-self" "center"]
      ["max-width" "100%"]
      ["min-height" "24px"]
      ["margin-top" "2px"]
      ["padding" "2px 6px"]
      ["color" "var(--t3)"]
      ["font-size" "12px"]
      ["cursor" "pointer"]
    ];
  }
  {
    select = "[data-role='omp.bot.event.row']:hover";
    set = [
      ["color" "var(--t2)"]
    ];
  }
  {
    select = "[data-role='omp.bot.event.action'], [data-role='omp.bot.event.more']";
    set = [
      ["flex" "none"]
      ["color" "var(--t3)"]
    ];
  }
  {
    select = "[data-role='omp.bot.event.name']";
    set = [
      ["max-width" "min(60vw, 360px)"]
      ["color" "var(--t2)"]
      ["font-weight" "500"]
    ];
  }
  {
    select = "[data-role='omp.bot.event.avatar']";
    set = [
      ["--p" "1px"]
      ["flex" "none"]
      ["width" "32px"]
      ["height" "26px"]
      ["overflow" "hidden"]
      ["align-items" "center"]
      ["justify-content" "center"]
      ["pointer-events" "none"]
    ];
  }
  {
    select = ":is([data-role='omp.bot.event.avatar']) *";
    set = [
      ["pointer-events" "none"]
    ];
  }
  {
    select = ":is([data-role='omp.bot.event.avatar']) :is([data-role='omp.bot.emote'], [data-role='omp.bot.chao.idle'] > [data-role='omp.bot.line']:empty)";
    set = [
      ["display" "none !important"]
    ];
  }
  {
    select = ":is([data-role='omp.bot.event.avatar']) :is([data-role^='omp.bot.glyph.'], [data-role='omp.bot.blink'] [data-role^='omp.bot.px.'], [data-role^='omp.bot.chao.'])";
    set = [
      ["animation" "none !important"]
    ];
  }
  {
    select = "[data-role='omp.bot.event.detail']";
    set = [
      ["align-self" "center"]
      ["width" "min(100%, 720px)"]
      ["margin" "4px auto 10px"]
    ];
  }
]
