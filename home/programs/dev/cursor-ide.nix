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
  cfg = config.cfg.home.programs.dev.cursor-ide;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.home.programs.dev.cursor-ide = {
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
