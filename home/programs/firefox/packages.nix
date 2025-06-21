###############################################################################
# Firefox Packages Module
# Firefox package installation and environment variables
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.shared) username;
in {
  config = lib.mkIf config.home.programs.firefox.enable {
    users.users.${username}.maid = {
      packages = with pkgs; [
        firefox
      ];

      file.home = {
        # Environment variables
        ".profile".text = lib.mkAfter ''
          # Firefox environment variables
          export MOZ_ENABLE_WAYLAND=1
          export MOZ_USE_XINPUT2=1
        '';
      };
    };
  };
}