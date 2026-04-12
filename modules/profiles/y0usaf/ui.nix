{
  pkgs,
  flakeInputs,
  ...
}: {
  user.ui = {
    ags = {
      enable = true;
      bar-overlay = {
        modules = ["time" "date" "tray"];
        exclusivity = "normal";
      };
    };
    gpuishell.enable = false;
    cursor.enable = true;
    fonts = {
      enable = true;
      mainFont = flakeInputs.fast-fonts.packages."${pkgs.stdenv.hostPlatform.system}".default;
      mainFontName = "Iosevka Term Slab";
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
    vicinae.enable = false;
    quickshell.enable = true;
    wayland.enable = true;
  };
}
