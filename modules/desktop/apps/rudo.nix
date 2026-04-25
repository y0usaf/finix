{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  userAppearance = config.user.appearance;
  uiFonts = config.user.ui.fonts;
in {
  options.user.programs.rudo = {
    enable = lib.mkEnableOption "Rudo terminal emulator";
  };

  config = lib.mkIf config.user.programs.rudo.enable {
    environment.systemPackages = [flakeInputs.rudo.packages."${system}".default];

    bayt.users."${config.user.name}".files = {
      ".config/rudo/config.toml" = {
        source = (pkgs.formats.toml {}).generate "rudo-config" (lib.recursiveUpdate {
            window = {
              inherit (userAppearance) opacity;
            };
            font = {
              size = userAppearance.termFontSize;
            };
            keybindings = {
              copy = "ctrl+c";
              paste = "ctrl+v";
            };
          } (lib.optionalAttrs uiFonts.enable {
            font.family = uiFonts.mainFontName;
          }));
      };
    };
  };
}
