#===============================================================================
#
#                     SSH Configuration
#
# Description:
#     SSH configuration file managing SSH connections and settings.
#     Includes:
#     - SSH key configurations
#     - Host-specific settings
#     - Connection parameters
#
# Author: y0usaf
# Last Modified: 2025
#
#===============================================================================
{
  config,
  pkgs,
  globals,
  ...
}: {
  programs.ssh = {
    enable = true;

    extraConfig = ''
      SetEnv TERM=xterm-256color
    '';

    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/Tokens/id_rsa_y0usaf";
      };
    };
  };
}
