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
    closeOnFocusLoss = false;
    considerPreedit = false;
    faviconService = "twenty";
    font = {
      size = scaledFontSize;
    };
    keybinding = "default";
    keybinds = {};
    popToRootOnClose = true;
    rootSearch = {
      searchFiles = false;
    };
    theme = {
      name = cfg.theme;
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
