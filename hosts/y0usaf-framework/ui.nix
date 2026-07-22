_: {
  user.ui = {
    moonshell = {
      enable = true;
      bar-overlay.modules = ["time" "date" "battery"];
      bar-overlay.edges = ["bottom"];
      bar-overlay.exclusive = true;
      bar-overlay.indent = 8;
      bar-overlay.bongo-cat.enable = true;
    };
    cursor.enable = true;
    fonts.enable = true;
    foot = {
      enable = true;
      lineHeight = "32px";
    };
    gtk = {
      enable = true;
      scale = 1.5;
    };
    tomoe = {
      layout = "sway";
      enable = true;
      displays = {
        "eDP-1" = {
          scale = 1;
        };
      };

      extraConfig = ''
        -- Keep the dmenu-style launcher/portal chooser out of the split tree.
        tomoe.rule { app_id = "^launcher$", floating = true }
      '';
    };
    wayland.enable = true;
  };
}
