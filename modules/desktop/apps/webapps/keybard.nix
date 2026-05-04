{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.keybard = {
    enable = lib.mkEnableOption "Keybard webapp";
  };
  config = lib.mkIf config.user.programs.keybard.enable {
    manzil.users."${config.user.name}" = {
      files = {
        ".local/share/applications/keybard.desktop" = {
          text = ''
            [Desktop Entry]
            Name=Keybard
            Exec=${lib.getExe pkgs.chromium} --app=https://captdeaf.github.io/keybard --enable-features=WebContentsForceDark %U
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
