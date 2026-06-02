{
  pkgs,
  flakeInputs,
  ...
}: {
  user.ui = {
    gpuishell.enable = true;
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
    foot = {
      enable = true;
      lineHeight = "32px";
    };
    gtk = {
      enable = true;
      scale = 1.0;
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
    sway.enable = false;
    vicinae.enable = false;
    quickshell.enable = true;
    wayland.enable = true;
  };
}
