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
in {
  options.user.programs.rudo = {
    enable = lib.mkEnableOption "Rudo terminal emulator";
  };

  config = lib.mkIf config.user.programs.rudo.enable {
    environment.systemPackages = [rudoPkg];

    bayt.users."${config.user.name}".files = {
      ".config/rudo/config.toml" = {
        source = (pkgs.formats.toml {}).generate "rudo-config" {
          window = {
            opacity = userAppearance.opacity;
          };
        };
      };
    };
  };
}
