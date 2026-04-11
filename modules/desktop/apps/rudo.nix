{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  rudoPkg = flakeInputs.rudo.packages."${system}".default;
  userAppearance = config.user.appearance;
  uiFonts = config.user.ui.fonts;

  rudoConfig =
    lib.recursiveUpdate {
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
    });
in {
  options.user.programs.rudo = {
    enable = lib.mkEnableOption "Rudo terminal emulator";
  };

  config = lib.mkIf config.user.programs.rudo.enable {
    environment.systemPackages = [rudoPkg];

    bayt.users."${config.user.name}".files = {
      ".config/rudo/config.toml" = {
        source = (pkgs.formats.toml {}).generate "rudo-config" rudoConfig;
      };
    };
  };
}
