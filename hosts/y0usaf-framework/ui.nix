_: {
  user.ui = {
    gpuishell.enable = true;
    cursor.enable = true;
    fonts.enable = true;
    foot = {
      enable = true;
      lineHeight = "32px";
    };
    gtk = {
      enable = true;
      scale = 1.0;
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
    quickshell.enable = true;
    wayland.enable = true;
  };
}
