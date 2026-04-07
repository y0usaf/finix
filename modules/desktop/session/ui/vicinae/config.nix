{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.ui.vicinae = {
    enable = lib.mkEnableOption "Vicinae launcher";
    scale = lib.mkOption {
      type = lib.types.float;
      default = 1.5;
      description = "UI scaling factor for vicinae. Multiplied by the base font size (10.5).";
    };
    fontName = lib.mkOption {
      type = lib.types.str;
      default = config.user.ui.fonts.mainFontName;
      description = "Font family to use in vicinae.";
    };
    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Extra configuration to merge into vicinae.json.";
    };
  };

  config = lib.mkIf config.user.ui.vicinae.enable {
    environment.systemPackages = [pkgs.vicinae];

    # Vicinae configuration via bayt
    bayt.users."${config.user.name}".files.".config/vicinae/vicinae.json" = {
      text = builtins.toJSON (lib.recursiveUpdate {
          # Vicinae defaults from config-service.hpp (with custom overrides)
          closeOnFocusLoss = false;
          considerPreedit = false;
          faviconService = "twenty"; # custom (default: "google")
          font = {
            size = 10.5 * config.user.ui.vicinae.scale; # custom scaling (default: 10.5)
            normal = config.user.ui.vicinae.fontName; # use main font from user.ui.fonts
          };
          keybinding = "default";
          keybinds = {};
          popToRootOnClose = true;
          rootSearch = {
            searchFiles = true; # real default (was overridden to false)
          };
          theme = {
            name = "wallust-auto"; # Always use wallust-generated theme
            # iconTheme = "...";  # optional: custom icon theme
          };
          window = {
            csd = true;
            opacity = 0.9;
            rounding = 0;
          };
        }
        config.user.ui.vicinae.extraConfig);
    };

    # Note: Wallust will generate the wallust-auto.toml theme based on colorscheme
    # This happens via the wallust template system when vicinae is enabled
  };
}
