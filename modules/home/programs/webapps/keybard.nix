{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.keybard;
in {
  options.home.programs.keybard = {
    enable = lib.mkEnableOption "Keybard webapp";
  };
  config = lib.mkIf cfg.enable {
    usr = {
      files = {
        ".local/share/applications/keybard.desktop" = {
          clobber = true;
          text = ''
            [Desktop Entry]
            Name=Keybard
            Exec=${lib.getExe pkgs.chromium} --app=https://captdeaf.github.io/keybard --force-dark-mode %U
            Terminal=false
            Type=Application
            Categories=Utility;System;
            Comment=Keyboard testing utility
          '';
        };
      };
    };
  };
}
