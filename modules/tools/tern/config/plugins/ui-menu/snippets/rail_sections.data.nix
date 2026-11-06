[
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt";
    set = [
      ["position" "relative"]
      ["overflow" "visible !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt::before, html.lay-rail.tabs-h .tb-tabs .tt::after";
    set = [
      ["display" "none !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2061\"]:first-child, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2061\"]) + .tt[title^=\"\\2061\"], html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2062\"]:first-child, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2062\"]) + .tt[title^=\"\\2062\"], html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2063\"]:first-child, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2063\"]) + .tt[title^=\"\\2063\"], html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2064\"]:first-child, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2064\"]) + .tt[title^=\"\\2064\"]";
    set = [
      ["margin-top" "34px !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2061\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2061\"]) + .tt[title^=\"\\2061\"]::after, html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2062\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2062\"]) + .tt[title^=\"\\2062\"]::after, html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2063\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2063\"]) + .tt[title^=\"\\2063\"]::after, html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2064\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2064\"]) + .tt[title^=\"\\2064\"]::after";
    set = [
      ["display" "block !important"]
      ["position" "absolute"]
      ["left" "10px"]
      ["top" "-26px"]
      ["width" "auto"]
      ["height" "auto"]
      ["background" "none"]
      ["box-shadow" "none"]
      ["font-size" "11px"]
      ["font-weight" "600"]
      ["letter-spacing" "0.06em"]
      ["text-transform" "uppercase"]
      ["color" "var(--t4)"]
      ["pointer-events" "none"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2061\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2061\"]) + .tt[title^=\"\\2061\"]::after";
    set = [
      ["content" "\"Pinned\""]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2062\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2062\"]) + .tt[title^=\"\\2062\"]::after";
    set = [
      ["content" "\"Needs you\""]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2063\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2063\"]) + .tt[title^=\"\\2063\"]::after";
    set = [
      ["content" "\"Working\""]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2064\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2064\"]) + .tt[title^=\"\\2064\"]::after";
    set = [
      ["content" "\"Idle\""]
    ];
  }
]
