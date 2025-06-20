###############################################################################
# Cursor IDE Development Module (Maid Version)
# Installs Cursor IDE using nix-maid package management
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.cursor-ide;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.dev.cursor-ide = {
    enable = lib.mkEnableOption "Cursor IDE";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid.packages = with pkgs; [
      code-cursor
    ];
  };
}
