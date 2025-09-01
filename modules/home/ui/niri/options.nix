{lib, ...}: let
  inherit (lib) types;
in {
  options.home.ui.niri = {
    enable = lib.mkEnableOption "Niri wayland compositor";

    settings = lib.mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Configuration for Niri wayland compositor.
        See https://github.com/YaLTeR/niri/wiki/Configuration:-Overview
        for available options.
      '';
      example = lib.literalExpression ''
        {
          input = {
            keyboard = {
              xkb = {
                layout = "us";
              };
            };
            touchpad = {
              tap = true;
              natural-scroll = true;
            };
          };

          layout = {
            gaps = 10;
            center-focused-column = "never";

            border = {
              width = 2;
              active-color = "#ffffff";
              inactive-color = "#333333";
            };
          };

          binds = {
            "Mod+T" = { spawn = "foot"; };
            "Mod+Q" = { close-window = true; };
          };
        }
      '';
    };

    extraConfig = lib.mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra configuration to append to the generated niri config.
        Useful for complex configurations that don't map well to Nix attributes.
      '';
      example = ''
        spawn-at-startup "swaybg" "-i" "/path/to/wallpaper" "-m" "fill"

        window-rule {
            match app-id="firefox"
            opacity 0.95
        }
      '';
    };
  };
}
