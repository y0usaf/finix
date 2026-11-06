[
  {
    select = "[data-role='omp.bot.words']";
    set = [
      ["min-width" "0"]
    ];
  }
  {
    select = "[data-role='omp.bot.name']";
    set = [
      ["font-weight" "600"]
    ];
  }
  {
    select = "[data-role='omp.bot.say'], [data-role='omp.bot.steps']";
    set = [
      ["position" "relative"]
      ["opacity" "0.58"]
    ];
  }
  {
    select = "[data-role^='omp.bot.top.'] [data-role='omp.bot.name']";
    set = [
      ["margin-left" "2px"]
    ];
  }
  {
    select = "[data-role='omp.bot.hello']";
    set = [
      ["margin-top" "14px"]
      ["font-size" "1.5em"]
      ["line-height" "1.3"]
      ["font-weight" "600"]
    ];
  }
]
