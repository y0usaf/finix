_: {
  user.ui = {
    foot.lineHeight = "32px";
    monstar.enable = true;
    tomoe = {
      layout = "sway";
      bar = {
        modules = ["time" "date" "battery" "network"];
        edges = ["bottom"];
        exclusive = true;
        indent = 8;
      };
      displays."eDP-1".scale = 1;
    };
  };
}
