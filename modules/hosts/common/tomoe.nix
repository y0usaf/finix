{lib, ...}: {
  user.ui = {
    cursor.enable = true;
    fonts.enable = true;
    foot.enable = true;
    monstar.enable = true;
    gtk = {
      enable = true;
      scale = 1.5;
    };
    wayland.enable = true;

    tomoe = {
      enable = true;
      bar.bongo-cat.enable = true;

      extraConfig = lib.mkBefore ''
        wm.honor_client_fullscreen = true
        tomoe.rule { app_id = "^launcher$", floating = true }
      '';
    };
  };
}
