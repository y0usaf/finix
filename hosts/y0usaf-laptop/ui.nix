_: {
  user.ui = {
    nur.enable = false; # replaced by moonshell (nur's successor)
    moonshell = {
      enable = true;
      # Laptop: battery shows the placeholder facade (static 100%) until
      # moonshell M3 §3 lands the native UPower backend.
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
