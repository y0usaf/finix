{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  termvidePkg = flakeInputs.termvide.packages."${system}".default;
  userAppearance = config.user.appearance;
in {
  options.user.programs.termvide = {
    enable = lib.mkEnableOption "Termvide terminal emulator";
  };

  config = lib.mkIf config.user.programs.termvide.enable {
    environment.systemPackages = [termvidePkg];

    bayt.users."${config.user.name}".files = {
      ".config/termvide/config.toml" = {
        source = (pkgs.formats.toml {}).generate "termvide-config" {
          wayland-app-id = "termvide";
          x11-wm-class = "termvide";
          x11-wm-class-instance = "termvide";

          transparency = userAppearance.opacity < 1.0;
          inherit (userAppearance) opacity;

          box-drawing.mode = "native";
        };
      };
    };
  };
}
