_: {
  imports = [../common/ui-tomoe.nix];

  user.ui = {
    foot = {
      enable = true;
      lineHeight = "32px";
    };
    gtk.scale = 1.5;
    tomoe = {
      layout = "sway";
      bar = {
        modules = ["time" "date" "battery" "network"];
        edges = ["bottom"];
        exclusive = true;
        indent = 8;
        bongo-cat.enable = true;
      };
      displays."eDP-1".scale = 1;
      extraConfig = ''
        wm.honor_client_fullscreen = true
      '';
    };
  };
}
