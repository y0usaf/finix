[
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt:not([data-tc]) .tn-dk::before, html.lay-rail.tabs-h .tb-tabs .tt:not([data-tc]) .tn-dk::after";
    set = [
      ["display" "none !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt:not([data-tc]) .tn-dk-c";
    set = [
      ["position" "relative"]
      ["overflow" "visible !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt:not([data-tc]) .tn-dk-c[data-st='working']::before";
    set = [
      ["inset" "-4px"]
      ["box-sizing" "border-box"]
      ["border" "2px dashed var(--pill)"]
      ["border-radius" "50%"]
      ["animation" "arc-spin 2.4s linear infinite"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt:not([data-tc]):is([title*=\"\\206B\"], [title*=\"\\206C\"], [title*=\"\\206D\"]) .tn-dk-c::before";
    set = [
      ["content" "\"\""]
      ["position" "absolute"]
      ["border-radius" "50%"]
      ["pointer-events" "none"]
      ["right" "-3px"]
      ["bottom" "-3px"]
      ["width" "10px"]
      ["height" "10px"]
      ["background" "var(--pill)"]
      ["box-shadow" "0 0 0 2px var(--panel)"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt:is(.working, [title*=\"\\206B\"], [title*=\"\\206C\"], [title*=\"\\206D\"]) .sub";
    set = [
      ["font-size" "0 !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt:is(.working, [title*=\"\\206B\"], [title*=\"\\206C\"], [title*=\"\\206D\"]) .sub::before";
    set = [
      ["font-size" "12px"]
      ["font-weight" "500"]
      ["font-family" "var(--sans)"]
      ["color" "var(--pill)"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt.working";
    set = [
      ["--pill" "light-dark(#0f766e, #5eead4)"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt.working .sub::before";
    set = [
      ["content" "\"Working\""]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206B\"]";
    set = [
      ["--pill" "light-dark(#b45309, #fbbf24)"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206B\"] .sub::before";
    set = [
      ["content" "\"Awaiting input\""]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206C\"]";
    set = [
      ["--pill" "light-dark(#15803d, #4ade80)"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206C\"] .sub::before";
    set = [
      ["content" "\"Done · unseen\""]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206D\"]";
    set = [
      ["--pill" "light-dark(#b91c1c, #f87171)"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206D\"] .sub::before";
    set = [
      ["content" "\"Failed · unseen\""]
    ];
  }
  {
    at = "@keyframes arc-spin";
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
    select = "html.lay-rail.tabs-h .tb-tabs .tt:not([data-tc]) .tn-dk-c::after";
    set = [
      ["display" "none !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt:is(.working, [title*=\"\\206B\"], [title*=\"\\206C\"], [title*=\"\\206D\"]) .sub > *";
    set = [
      ["display" "none !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt:is(.working, [title*=\"\\206B\"], [title*=\"\\206C\"], [title*=\"\\206D\"]) .sub::after";
    set = [
      ["display" "none !important"]
    ];
  }
]
