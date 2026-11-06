[
  {
    select = "html.lay-rail.tabs-h #tabbar > .tb-in > .tn-peers";
    set = [
      ["order" "1 !important"]
      ["margin-top" "0 !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h #tabbar";
    set = [
      ["overflow-y" "auto !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h #tabbar > .tb-in";
    set = [
      ["flex" "none !important"]
      ["min-height" "100% !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h #tabbar > .tb-in > .tb-tabs";
    set = [
      ["flex" "none !important"]
      ["margin" "0 !important"]
      ["overflow" "visible !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h #tabbar > .tb-in > .tb-add";
    set = [
      ["margin-top" "auto !important"]
    ];
  }
]
