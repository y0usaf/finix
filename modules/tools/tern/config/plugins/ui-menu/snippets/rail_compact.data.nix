[
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt";
    set = [
      ["height" "38px !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206E\"]:not([data-tc])";
    set = [
      ["height" "20px !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206E\"]:not([data-tc]) .sub";
    set = [
      ["display" "none !important"]
    ];
  }
]
