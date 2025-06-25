#===============================================================================
# 🐱 Cat Fetch Display Module for Maid 🐱
# Provides colorful cat display functionality for shell startup
#===============================================================================
{
  config,
  lib,
  ...
}: let
  cfg = config.home.shell.cat-fetch;
in {
  #===========================================================================
  # Module Options
  #===========================================================================
  options.home.shell.cat-fetch = {
    enable = lib.mkEnableOption "cat fetch display on shell startup";
  };

  #===========================================================================
  # Module Configuration
  #===========================================================================
  config = lib.mkIf cfg.enable {
    # This module just provides the option - the actual functionality
    # is implemented in zsh.nix using the shared.zsh.cat-fetch option
  };
}