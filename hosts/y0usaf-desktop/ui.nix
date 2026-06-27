_: {
  user.ui = {
    nur.enable = true;
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
    shojiwm.enable = true;
    wayland.enable = true;
  };
}
