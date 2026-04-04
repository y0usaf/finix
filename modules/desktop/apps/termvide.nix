{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  termvidePkg = flakeInputs.termvide.packages."${system}".default;
  uiFonts = config.user.ui.fonts;
in {
  options.user.programs.termvide = {
    enable = lib.mkEnableOption "Termvide terminal emulator";
  };

  config = lib.mkIf config.user.programs.termvide.enable {
    environment.systemPackages = [termvidePkg];

    bayt.users."${config.user.name}".files = {
      # Termvide still reads the legacy Neovide config path upstream.
      ".config/neovide/config.toml" = {
        clobber = true;
        source = (pkgs.formats.toml {}).generate "termvide-config" {
          wayland-app-id = "termvide";
          x11-wm-class = "termvide";
          x11-wm-class-instance = "termvide";

          font = {
            normal = [
              uiFonts.mainFontName
              "Symbols Nerd Font"
              uiFonts.backup.name
              uiFonts.emoji.name
            ];
            size = config.user.appearance.termFontSize;
            features."${uiFonts.mainFontName}" = [
              "-calt"
              "-liga"
              "-clig"
              "-dlig"
            ];
          };

          box-drawing.mode = "native";
        };
      };
    };
  };
}
