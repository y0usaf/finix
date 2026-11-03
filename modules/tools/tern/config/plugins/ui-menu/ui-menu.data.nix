[
  {
    select = ".uo-list";
    set = [
      ["display" "flex"]
      ["flex-direction" "column"]
      ["gap" "1px"]
      ["padding" "8px 10px"]
      ["max-width" "520px"]
    ];
  }
  {
    select = ".uo-group";
    set = [
      ["margin" "14px 0 4px"]
      ["font" "10px/14px var(--mono)"]
      ["letter-spacing" "0.08em"]
      ["text-transform" "uppercase"]
      ["color" "var(--t4)"]
    ];
  }
  {
    select = ".uo-row";
    set = [
      ["display" "flex"]
      ["align-items" "center"]
      ["gap" "10px"]
      ["padding" "6px 8px"]
      ["border-radius" "8px"]
      ["cursor" "pointer"]
    ];
  }
  {
    select = ".uo-row:hover";
    set = [
      ["background" "var(--l1)"]
    ];
  }
  {
    select = ".uo-row input";
    set = [
      ["width" "15px"]
      ["height" "15px"]
      ["margin" "0"]
    ];
  }
  {
    select = ".uo-name";
    set = [
      ["color" "var(--t1)"]
    ];
  }
]
