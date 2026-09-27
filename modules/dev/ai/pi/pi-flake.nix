{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  config = lib.mkIf config.user.dev.pi.enable {
    environment.systemPackages = [
      flakeInputs.pi-harness.packages."${pkgs.stdenv.hostPlatform.system}".default
      flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".pi
    ];
  };
}
