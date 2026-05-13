{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) mkAfter;
  cursorsPkgs = flakeInputs.cursors.packages."${pkgs.stdenv.hostPlatform.system}";
  inherit (config) user;
  inherit (user) shell;
  inherit (user.appearance) hyprcursorSize xcursorSize;
  cursor = user.ui.cursor;
  cursorPackage = cursor.package;
  cursorSessionVariables = cursorPackage.mkCursorSessionVariables {
    inherit xcursorSize hyprcursorSize;
  };
  zshSessionVariables = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: ''export ${name}="${value}"'') cursorSessionVariables);
  nushellSessionVariables = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: ''$env.${name} = "${value}"'') cursorSessionVariables);
in {
  options.user.ui.cursor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable cursor theme configuration";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = cursorsPkgs.popucom-pink;
      description = ''
        Combined cursor theme package. The package is expected to expose cursor
        metadata through passthru, including xcursorThemeName and
        mkCursorSessionVariables.
      '';
    };
  };

  config = lib.mkIf cursor.enable {
    environment.systemPackages = cursorPackage.cursorPackages or [cursorPackage];

    manzil.users."${user.name}" = {
      files =
        {
          ".config/gtk-3.0/settings.ini" = {
            text = mkAfter ''
              [Settings]
              gtk-cursor-theme-name=${cursorPackage.xcursorThemeName}
              gtk-cursor-theme-size=${toString xcursorSize}
            '';
          };
          ".config/gtk-4.0/settings.ini" = {
            text = mkAfter ''
              [Settings]
              gtk-cursor-theme-name=${cursorPackage.xcursorThemeName}
              gtk-cursor-theme-size=${toString xcursorSize}
            '';
          };
        }
        // lib.optionalAttrs shell.zsh.enable {
          ".config/zsh/.zprofile" = {
            text = mkAfter ''
              ${zshSessionVariables}
            '';
          };
        }
        // lib.optionalAttrs shell.nushell.enable {
          ".config/nushell/login.nu" = {
            text = mkAfter ''
              ${nushellSessionVariables}
            '';
          };
        };
    };
  };
}
