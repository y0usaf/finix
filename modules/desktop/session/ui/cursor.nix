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
  inherit (user.appearance) cursorSize cursorColor cursorTheme;
  colorCap = let
    first = builtins.substring 0 1 cursorColor;
    rest = builtins.substring 1 (-1) cursorColor;
  in
    (lib.toUpper first) + rest;

  isPopucom = cursorTheme == "popucom";

  popucom = {
    x11ThemeName = "Popucom-${colorCap}-x11";
    hyprThemeName = "Popucom-${colorCap}-hypr";
    xcursorPackage = cursorsPkgs."popucom-${cursorColor}-xcursor";
    hyprcursorPackage = cursorsPkgs."popucom-${cursorColor}-hyprcursor";
  };

  deepinPkg = pkgs.stdenv.mkDerivation {
    name = "deepin-cursor-theme";
    src = pkgs.fetchFromGitHub {
      owner = "martyr-deepin";
      repo = "deepin-cursor-theme";
      rev = "a7b5459c31c5edecbfded3fa87ef38e673f3470c";
      hash = "sha256-AQloWzwzBmpavxosQQrPHOzCQ4Gb5/LpSMM+M2J+M7M=";
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/icons
      cp -r Deepin-Cursor $out/share/icons/
    '';
  };

  deepin = {
    x11ThemeName = "Deepin-Cursor";
    xcursorPackage = deepinPkg;
  };

  theme =
    if isPopucom
    then popucom
    else deepin;
in {
  options.user.ui.cursor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable cursor theme configuration";
    };
  };
  config = lib.mkIf user.ui.cursor.enable {
    environment.systemPackages =
      [theme.xcursorPackage]
      ++ lib.optional isPopucom popucom.hyprcursorPackage;

    bayt.users."${user.name}" = {
      files =
        {
          ".config/gtk-3.0/settings.ini" = {
            text = mkAfter ''
              [Settings]
              gtk-cursor-theme-name=${theme.x11ThemeName}
              gtk-cursor-theme-size=${toString cursorSize}
            '';
            clobber = true;
          };
          ".config/gtk-4.0/settings.ini" = {
            text = mkAfter ''
              [Settings]
              gtk-cursor-theme-name=${theme.x11ThemeName}
              gtk-cursor-theme-size=${toString cursorSize}
            '';
            clobber = true;
          };
        }
        // lib.optionalAttrs shell.zsh.enable {
          ".config/zsh/.zprofile" = {
            text = mkAfter (''
                export XCURSOR_THEME="${theme.x11ThemeName}"
                export XCURSOR_SIZE="${toString cursorSize}"
              ''
              + lib.optionalString isPopucom ''
                export HYPRCURSOR_THEME="${popucom.hyprThemeName}"
                export HYPRCURSOR_SIZE="${toString cursorSize}"
              '');
            clobber = true;
          };
        }
        // lib.optionalAttrs shell.nushell.enable {
          ".config/nushell/login.nu" = {
            text = mkAfter (''
                $env.XCURSOR_THEME = "${theme.x11ThemeName}"
                $env.XCURSOR_SIZE = "${toString cursorSize}"
              ''
              + lib.optionalString isPopucom ''
                $env.HYPRCURSOR_THEME = "${popucom.hyprThemeName}"
                $env.HYPRCURSOR_SIZE = "${toString cursorSize}"
              '');
            clobber = true;
          };
        };
    };
  };
}
