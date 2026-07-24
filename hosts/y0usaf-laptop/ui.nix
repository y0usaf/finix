_: {
  user.ui = {
    moonshell = {
      enable = true;
      # Battery is native (UPower over rustbus, sysfs fallback) since
      # moonshell M3 §3 / the fusion.
      bar-overlay.modules = ["time" "date" "battery"];
    };
    cursor.enable = true;
    fonts.enable = true;
    foot.enable = true;
    gtk = {
      enable = true;
      scale = 1.5;
    };
    niri = {
      enable = true;
      extraConfig = ''
        window-rule {
          match app-id="launcher"
          open-floating true
        }
      '';
    };
    wayland.enable = true;
  };
}
