[
  {
    select = "#tabbar .tt[data-tc='red']";
    set = [
      ["--bot" "#ff4d5e"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc='orange']";
    set = [
      ["--bot" "#ff8a3d"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc='yellow']";
    set = [
      ["--bot" "#f2b705"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc='green']";
    set = [
      ["--bot" "#2fbf71"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc='teal']";
    set = [
      ["--bot" "#19b8c4"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc='blue']";
    set = [
      ["--bot" "#3d7bff"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc='purple']";
    set = [
      ["--bot" "#8f6bff"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc='pink']";
    set = [
      ["--bot" "#ff5fa8"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc]";
    set = [
      ["border" "none"]
      ["box-shadow" "none"]
      ["border-radius" "10px"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc].on";
    set = [
      ["background" "light-dark(#ececee, #2a2a2d) !important"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc] .mk.keys, #tabbar .tt[data-tc] .kbd, #tabbar .tt[data-tc] .tn-tc";
    set = [
      ["display" "none"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc] .nm";
    set = [
      ["color" "light-dark(#18181b, #f2f2f3)"]
      ["font-weight" "500"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc] .sub";
    set = [
      ["opacity" "0.55"]
      ["font-size" "11px"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc] .sub::after";
    set = [
      ["font-family" "var(--sans)"]
      ["font-size" "11.5px"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc] .tn-dk-c";
    set = [
      ["position" "relative"]
      ["width" "18px"]
      ["height" "18px"]
      ["color" "transparent"]
      ["background" "none"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc] .tn-dk-c *";
    set = [
      ["opacity" "0"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc] .tn-dk-c::after";
    set = [
      ["content" "''"]
      ["position" "absolute"]
      ["left" "-30px"]
      ["top" "-30px"]
      ["width" "1px"]
      ["height" "1px"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc] .tn-dk-c[data-st='waiting']::before, #tabbar .tt[data-tc] .tn-dk-c[data-st='failed']::before";
    set = [
      ["content" "''"]
      ["position" "absolute"]
      ["z-index" "1"]
      ["right" "-4px"]
      ["top" "-6px"]
      ["width" "4px"]
      ["height" "4px"]
      ["background" "#f0a020"]
      ["box-shadow" "0 0 0 1px #000"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc] .tn-dk-c[data-st='working']";
    set = [
      ["animation" "railChaoBob 0.8s steps(1) infinite"]
    ];
  }
  {
    select = "#tabbar .tt[data-tc] .tn-dk-c[data-st='failed']::before";
    set = [
      ["background" "#e5484d"]
    ];
  }
  {
    at = "@keyframes railChaoBob";
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
          ["transform" "translateY(-1px)"]
        ];
      }
    ];
  }
  {
    at = "@media (prefers-reduced-motion: reduce)";
    rules = [
      {
        select = "#tabbar .tt[data-tc] .tn-dk-c[data-st='working']";
        set = [
          ["animation" "none"]
        ];
      }
    ];
  }
]
