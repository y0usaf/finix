{
  pkgs,
  flakeInputs,
  ...
}: {
  user.ui = {
    ags = {
      enable = false;
      bar-overlay = {
        modules = ["time" "date" "tray"];
        exclusivity = "normal";
      };
    };
    nur.enable = true;
    gpuishell.enable = false;
    cursor.enable = true;
    fonts = {
      enable = true;
      mainFont = flakeInputs.fonts.packages."${pkgs.stdenv.hostPlatform.system}".default;
      mainFontName = "Departure Mono Condensed Compact";
      backup = {
        package = pkgs.noto-fonts-cjk-sans;
        name = "Noto Sans CJK";
      };
    };
    foot.enable = true;
    gtk = {
      enable = true;
      scale = 1.5;
    };
    hyprland.enable = true;
    mangowc.enable = false;
    niri = {
      enable = true;
      extraConfig = ''
        window-rule {
          match app-id="launcher"
          open-floating true
        }
      '';
    };
    sway.enable = true;
    vicinae.enable = false;
    quickshell.enable = false;
    wayland.enable = true;
  };
}
