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
    # Consume the source flake's own package; keep the upstream flake's
    # tested nixpkgs pin rather than following Finix's nixpkgs input.
    environment.systemPackages = [
      flakeInputs.emeraldian.packages."${system}".default
    ];
  };
}
