{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  options.user.programs.emeraldian = {
    enable = mkEnableOption "Emeraldian Obsidian vault terminal UI";
  };

  config = mkIf config.user.programs.emeraldian.enable {
    environment.systemPackages = [
      flakeInputs.emeraldian.packages."${system}".default
    ];
  };
}
