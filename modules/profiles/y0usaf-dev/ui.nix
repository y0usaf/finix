{
  flakeInputs,
  pkgs,
  ...
}: {
  user.ui = {
    gpuishell.enable = true;
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
      scale = 1.0;
    };
    hyprland.enable = false;
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
