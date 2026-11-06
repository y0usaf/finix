[
  {
    select = ":root:not(#oz) [data-role^='omp.bot.time.']";
    set = [
      ["font" "400 11px/1 var(--sans)"]
      ["letter-spacing" "1.5px"]
      ["text-transform" "uppercase"]
      ["color" "var(--t3)"]
    ];
  }
  {
    select = ":root:not(#oz) [data-role^='omp.bot.top.']";
    set = [
      ["box-shadow" "0 1px 0 var(--l3)"]
    ];
  }
  {
    select = ":root:not(#oz) [data-role^='omp.bot.top.'] [data-role='omp.bot.name']";
    set = [
      ["font" "400 16.5px/24px var(--sans)"]
      ["letter-spacing" "2.5px"]
      ["text-transform" "uppercase"]
      ["color" "var(--ink)"]
    ];
  }
  {
    select = ":root:not(#oz) [data-role='omp.bot.event.row']";
    set = [
      ["font" "400 11px/16px var(--sans)"]
      ["letter-spacing" "1.5px"]
      ["text-transform" "uppercase"]
      ["color" "var(--t3)"]
    ];
  }
  {
    select = ":root:not(#oz) [data-role='omp.bot.event.name']";
    set = [
      ["font" "inherit"]
      ["color" "var(--ink)"]
    ];
  }
  {
    select = ":root:not(#oz) [data-role='omp.bot.hello']";
    set = [
      ["font" "400 22px/30px var(--sans)"]
      ["letter-spacing" "2.5px"]
      ["text-transform" "uppercase"]
    ];
  }
  {
    select = ":root:not(#oz) [data-role='omp.bot.say']";
    set = [
      ["font" "400 11px/16px var(--sans)"]
      ["letter-spacing" "0"]
      ["color" "var(--t2)"]
      ["opacity" "1"]
    ];
  }
  {
    select = ":root:not(#oz) [data-role='omp.bot.say']::after";
    set = [
      ["content" "\"\""]
      ["display" "inline-block"]
      ["width" "7px"]
      ["height" "12px"]
      ["margin-left" "6px"]
      ["vertical-align" "-2px"]
      ["background" "var(--ink)"]
      ["animation" "yh-blink calc(1000ms * var(--yh-t)) steps(1, end) 4"]
    ];
  }
]
