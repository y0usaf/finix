{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home.programs.keybard = {
    enable = lib.mkEnableOption "Keybard webapp";
  };
  config = lib.mkIf config.home.programs.keybard.enable {
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
