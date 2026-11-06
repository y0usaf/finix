[
  {
    select = "[data-role='omp.bot.blink']";
    set = [
      ["position" "absolute"]
      ["inset" "0"]
      ["align-items" "center"]
    ];
  }
  {
    select = "[data-role='omp.bot.blink'] [data-role^='omp.bot.px.']";
    set = [
      ["opacity" "0"]
      ["animation" "chaoBlink 5.2s steps(1) infinite"]
    ];
  }
  {
    select = "[data-role^='omp.bot.glyph.']";
    set = [
      ["animation" "chaoBob 1.8s steps(1) infinite"]
    ];
  }
  {
    select = "[data-role='omp.bot.glyph.swirl']";
    set = [
      ["animation" "chaoSpin 0.8s steps(4) infinite"]
    ];
  }
  {
    select = "[data-role='omp.bot.glyph.ask']";
    set = [
      ["animation" "chaoSway 1.2s steps(1) infinite"]
    ];
  }
  {
    select = "[data-role='omp.bot.glyph.bang']";
    set = [
      ["animation-duration" "0.5s"]
    ];
  }
  {
    select = "[data-role='omp.bot.glyph.heart']";
    set = [
      ["animation" "chaoRise 1s steps(5) 1 both"]
    ];
  }
  {
    select = "[data-role='omp.bot.glyph.droop']";
    set = [
      ["transform" "translateY(calc(2 * var(--p)))"]
      ["animation" "none"]
    ];
  }
  {
    select = "[data-role='omp.bot.glyph.z']";
    set = [
      ["animation" "chaoZ 2.4s steps(6) infinite"]
    ];
  }
  {
    select = "[data-role='omp.bot.chao.drowsy'] [data-role^='omp.bot.glyph.']";
    set = [
      ["animation-duration" "4s"]
    ];
  }
  {
    select = "[data-role='omp.bot.tempo.calm'] [data-role^='omp.bot.glyph.']";
    set = [
      ["animation-duration" "2.6s"]
    ];
  }
  {
    select = "[data-role='omp.bot.tempo.brisk'] [data-role^='omp.bot.glyph.']";
    set = [
      ["animation-duration" "1.2s"]
    ];
  }
  {
    select = "[data-role='omp.bot.tempo.calm'] [data-role='omp.bot.blink'] [data-role^='omp.bot.px.']";
    set = [
      ["animation-duration" "7s"]
    ];
  }
  {
    select = "[data-role='omp.bot.tempo.brisk'] [data-role='omp.bot.blink'] [data-role^='omp.bot.px.']";
    set = [
      ["animation-duration" "3.6s"]
    ];
  }
  {
    select = "[data-role='omp.bot.chao.happy'], [data-role='omp.bot.chao.boop'], [data-role='omp.bot.chao.listen'], [data-role^='omp.bot.chao.']:hover";
    set = [
      ["animation" "chaoHop 0.6s cubic-bezier(0.3, 0.7, 0.4, 1) 1"]
    ];
  }
  {
    select = "[data-role='omp.bot.chao.sleep']:hover";
    set = [
      ["animation" "none"]
    ];
  }
  {
    at = "@keyframes chaoBlink";
    rules = [
      {
        select = "0%, 100%";
        set = [
          ["opacity" "0"]
        ];
      }
      {
        select = "92%, 96%";
        set = [
          ["opacity" "1"]
        ];
      }
    ];
  }
  {
    at = "@keyframes chaoBob";
    rules = [
      {
        select = "0%, 100%";
        set = [
          ["transform" "translateY(0)"]
        ];
      }
      {
        select = "50%";
        set = [
          ["transform" "translateY(calc(-1 * var(--p)))"]
        ];
      }
    ];
  }
  {
    at = "@keyframes chaoSpin";
    rules = [
      {
        select = "from";
        set = [
          ["transform" "rotate(0deg)"]
        ];
      }
      {
        select = "to";
        set = [
          ["transform" "rotate(360deg)"]
        ];
      }
    ];
  }
  {
    at = "@keyframes chaoSway";
    rules = [
      {
        select = "0%, 100%";
        set = [
          ["transform" "translateX(0)"]
        ];
      }
      {
        select = "50%";
        set = [
          ["transform" "translateX(var(--p))"]
        ];
      }
    ];
  }
  {
    at = "@keyframes chaoRise";
    rules = [
      {
        select = "from";
        set = [
          ["transform" "translateY(calc(3 * var(--p)))"]
        ];
      }
      {
        select = "to";
        set = [
          ["transform" "translateY(0)"]
        ];
      }
    ];
  }
  {
    at = "@keyframes chaoZ";
    rules = [
      {
        select = "from";
        set = [
          ["opacity" "1"]
          ["transform" "translate(0, 0)"]
        ];
      }
      {
        select = "to";
        set = [
          ["opacity" "0"]
          ["transform" "translate(calc(3 * var(--p)), calc(-4 * var(--p)))"]
        ];
      }
    ];
  }
  {
    at = "@keyframes chaoHop";
    rules = [
      {
        select = "0%, 100%";
        set = [
          ["transform" "translateY(0)"]
        ];
      }
      {
        select = "40%";
        set = [
          ["transform" "translateY(calc(-5 * var(--p)))"]
        ];
      }
      {
        select = "70%";
        set = [
          ["transform" "translateY(0)"]
        ];
      }
    ];
  }
  {
    at = "@media (prefers-reduced-motion: reduce)";
    rules = [
      {
        select = "[data-role^='omp.bot.chao.'], [data-role^='omp.bot.chao.'] *";
        set = [
          ["animation" "none !important"]
        ];
      }
    ];
  }
]
