[
  {
    select = "html.lay-rail.tabs-h #tabbar .tb-in";
    set = [
      ["position" "relative !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h #tabbar .tb-in > .tb-add, html.lay-rail.tabs-h #tabbar .tb-in > .tn-ib-badge";
    set = [
      ["position" "absolute !important"]
      ["top" "4px !important"]
      ["width" "28px !important"]
      ["height" "26px !important"]
      ["margin" "0 !important"]
      ["padding" "0 !important"]
      ["justify-content" "center !important"]
      ["gap" "0 !important"]
      ["border-radius" "7px !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h #tabbar .tb-in > .tb-add";
    set = [
      ["right" "40px !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h #tabbar .tb-in > .tn-ib-badge";
    set = [
      ["right" "8px !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h #tabbar .tb-in > :is(.tb-add, .tn-ib-badge) :is(.lbl, .kbds)";
    set = [
      ["display" "none !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h #tabbar .tb-in > .tn-ib-badge .tn-ib-pip";
    set = [
      ["position" "absolute !important"]
      ["top" "1px !important"]
      ["right" "1px !important"]
      ["margin" "0 !important"]
      ["transform" "scale(0.8)"]
    ];
  }
]
