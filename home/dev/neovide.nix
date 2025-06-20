###############################################################################
# Minimal Neovide Configuration for Development
# Just font configuration - no vsync, no desktop entry
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
  
  # Get font configuration from appearance module
  mainFontName = (builtins.elemAt config.home.core.appearance.fonts.main 0).name;
  fontSize = toString (config.home.core.appearance.baseFontSize * 1.0);
in {
  ###########################################################################
  # Minimal Neovide Configuration (when enabled via nvim.neovide option)
  ###########################################################################
  config = lib.mkIf (cfg.enable && cfg.neovide) {
    users.users.${username}.maid = {
      packages = with pkgs; [
        neovide
      ];

      # Minimal Neovide configuration
      file.home = {
        ".config/neovide/config.toml".text = ''
          # Font configuration only
          [font]
          normal = ["${mainFontName}"]
          size = ${fontSize}.0
        '';
      };
    };
  };
}