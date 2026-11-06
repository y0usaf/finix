[
  {
    select = "[data-role^='omp.bot.tempo.'], [data-role^='omp.bot.type.']";
    set = [
      ["position" "relative"]
      ["flex" "none"]
    ];
  }
  {
    select = "[data-role='omp.bot.type.neutral']";
    set = [
      ["--xb" "color-mix(in srgb, var(--t) 35%, #fff)"]
      ["--xm" "color-mix(in srgb, var(--t) 50%, #fff)"]
      ["--xs" "color-mix(in srgb, var(--t) 70%, #fff)"]
      ["--xc" "color-mix(in srgb, var(--t) 82%, #000)"]
      ["--xe" "color-mix(in srgb, var(--t) 55%, #000)"]
      ["--xw" "#f8f8f8"]
      ["--xa" "#f8f820"]
      ["--xi" "#d8d868"]
      ["--xd" "#c0b830"]
      ["--xn" "#88a850"]
      ["--xj" "#d8f8b0"]
    ];
  }
  {
    select = "[data-role='omp.bot.type.hero']";
    set = [
      ["--xb" "#f8f8f8"]
      ["--xs" "#bec2bf"]
      ["--xc" "#647c9a"]
      ["--xe" "#647c9a"]
      ["--xw" "#f8f8f8"]
      ["--xj" "#c8ebf1"]
      ["--xa" "#89a8dd"]
      ["--xi" "#c8ebf1"]
      ["--xd" "#647c9a"]
      ["--xy" "#f7df56"]
    ];
  }
  {
    select = "[data-role='omp.bot.type.dark']";
    set = [
      ["--xb" "color-mix(in srgb, var(--t) 22%, #152745)"]
      ["--xe" "#1c63a1"]
      ["--xw" "#f8f8f8"]
      ["--xa" "#d52b38"]
      ["--xi" "#d52b38"]
      ["--xd" "#a71a30"]
    ];
  }
  {
    select = "[data-role^='omp.bot.chao.']";
    set = [
      ["position" "relative"]
      ["flex" "none"]
      ["align-items" "flex-start"]
      ["cursor" "pointer"]
    ];
  }
  {
    select = "[data-role='omp.bot.emote']";
    set = [
      ["flex" "none"]
      ["align-items" "flex-end"]
    ];
  }
  {
    select = "[data-role='omp.bot.body']";
    set = [
      ["position" "relative"]
      ["align-items" "center"]
    ];
  }
  {
    select = "[data-role='omp.bot.line']";
    set = [
      ["flex" "none"]
      ["height" "var(--p)"]
      ["justify-content" "center"]
    ];
  }
  {
    select = "[data-role^='omp.bot.px.']";
    set = [
      ["flex" "none"]
      ["width" "var(--p)"]
      ["height" "var(--p)"]
    ];
  }
  {
    select = "[data-role='omp.bot.px.o']";
    set = [
      ["background" "light-dark(#000, #44485e)"]
    ];
  }
  {
    select = "[data-role='omp.bot.px.r']";
    set = [
      ["background" "#ff4f7b"]
    ];
  }
  {
    select = "[data-role='omp.bot.px.b']";
    set = [
      ["background" "var(--xb)"]
    ];
  }
  {
    select = "[data-role='omp.bot.px.m']";
    set = [
      ["background" "var(--xm)"]
    ];
  }
  {
    select = "[data-role='omp.bot.px.s']";
    set = [
      ["background" "var(--xs)"]
    ];
  }
  {
    select = "[data-role='omp.bot.px.c']";
    set = [
      ["background" "var(--xc)"]
    ];
  }
  {
    select = "[data-role='omp.bot.px.e']";
    set = [
      ["background" "var(--xe)"]
    ];
  }
  {
    select = "[data-role='omp.bot.px.a']";
    set = [
      ["background" "var(--xa)"]
    ];
  }
  {
    select = "[data-role='omp.bot.px.i']";
    set = [
      ["background" "var(--xi)"]
    ];
  }
  {
    select = "[data-role='omp.bot.px.d']";
    set = [
      ["background" "var(--xd)"]
    ];
  }
  {
    select = "[data-role='omp.bot.px.n']";
    set = [
      ["background" "var(--xn)"]
    ];
  }
  {
    select = "[data-role='omp.bot.px.j']";
    set = [
      ["background" "var(--xj)"]
    ];
  }
  {
    select = "[data-role='omp.bot.px.w']";
    set = [
      ["background" "var(--xw)"]
    ];
  }
  {
    select = "[data-role='omp.bot.px.y']";
    set = [
      ["background" "var(--xy)"]
    ];
  }
]
