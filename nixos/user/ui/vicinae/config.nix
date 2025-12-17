{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.ui.vicinae;
  baseFontSize = 10.5;
  scaledFontSize = baseFontSize * cfg.scale;
  vicinaeConfig = {
    # Vicinae defaults from config-service.hpp (with custom overrides)
    closeOnFocusLoss = false;
    considerPreedit = false;
    faviconService = "twenty"; # custom (default: "google")
    font = {
      size = scaledFontSize; # custom scaling (default: 10.5)
      # normal = "Monospace";  # optional: custom font family
    };
    keybinding = "default";
    keybinds = {};
    popToRootOnClose = true;
    rootSearch = {
      searchFiles = true; # real default (was overridden to false)
    };
    theme = {
      name = cfg.theme; # custom (default: "vicinae-dark")
      # iconTheme = "...";  # optional: custom icon theme
    };
    window = {
      csd = true;
      opacity = 0.98;
      rounding = 10;
    };
  };
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.vicinae];

    # Vicinae configuration via hjem
    usr.files.".config/vicinae/vicinae.json" = {
      text = builtins.toJSON (lib.recursiveUpdate vicinaeConfig cfg.extraConfig);
    };

    # Note: Wallust will generate the wallust-auto.toml theme based on colorscheme
    # This happens via the wallust template system when vicinae is enabled
  };
}
