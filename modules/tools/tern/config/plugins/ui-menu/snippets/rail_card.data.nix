[
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt";
    set = [
      ["border-radius" "8px !important"]
      ["box-shadow" "none !important"]
      ["color" "var(--t3) !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt:hover";
    set = [
      ["background" "color-mix(in srgb, var(--t1) 6%, transparent) !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt.on";
    set = [
      ["background" "var(--panel) !important"]
      ["box-shadow" "inset 0 0 0 1px var(--l2) !important"]
      ["color" "var(--t1) !important"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt.on .nm";
    set = [
      ["font-weight" "600"]
    ];
  }
  {
    select = "html.lay-rail.tabs-h .tb-tabs .tt.on::before, html.lay-rail.tabs-h .tb-tabs .tt.on::after";
    set = [
      ["display" "none !important"]
    ];
  }
]
