# Shared Tomoe defaults for graphical hosts. Host modules keep only display,
# layout, bar, and machine-specific Lua settings.
{lib, ...}: {
  user.ui = {
    cursor.enable = true;
    fonts.enable = true;
    foot.enable = true;
    gtk = {
      enable = true;
      scale = 1.5;
    };
    wayland.enable = true;

    tomoe = {
      enable = true;
      bar.bongo-cat.enable = true;

      # mkBefore: host extraConfig (lines type) appends after this chunk.
      extraConfig = lib.mkBefore ''
        -- Browser/video/game controls may request real output fullscreen.
        wm.honor_client_fullscreen = true
        -- Keep the dmenu-style launcher out of the tiling (split tree / deck).
        tomoe.rule { app_id = "^launcher$", floating = true }
      '';
    };
  };
}
