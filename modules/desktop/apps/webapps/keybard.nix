{
  config,
  lib,
  pkgs,
  ...
}: {
  manzil.users."${config.user.name}" = {
    files = {
      ".local/share/applications/keybard.desktop" = {
        generator = lib.generators.toINI {};
        value."Desktop Entry" = {
          Name = "Keybard";
          Exec = "${lib.getExe pkgs.chromium} --app=https://captdeaf.github.io/keybard --enable-features=WebContentsForceDark %U";
          Terminal = false;
          Type = "Application";
          Categories = "Utility;System;";
          Comment = "Keyboard testing utility";
        };
      };
    };
  };
}
