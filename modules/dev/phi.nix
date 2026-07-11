{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.dev.phi = {
    enable = lib.mkEnableOption "Phi coding harness";
  };

  config = lib.mkIf config.user.dev.phi.enable {
    environment.systemPackages = [
      flakeInputs.phi.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];
  };
}
