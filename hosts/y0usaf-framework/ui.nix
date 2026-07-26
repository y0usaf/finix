_: {
  user.ui = {
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
      bar = {
        modules = ["time" "date" "battery" "network"];
        edges = ["bottom"];
        exclusive = true;
        indent = 8;
        bongo-cat.enable = true;
      };
      displays = {
        "eDP-1" = {
          scale = 1;
        };
      };

      extraConfig = ''
        -- Browser/video/game controls may request real output fullscreen.
        wm.honor_client_fullscreen = true
        -- Keep the dmenu-style launcher out of the split tree.
        tomoe.rule { app_id = "^launcher$", floating = true }
      '';
    };
    wayland.enable = true;
  };
}
