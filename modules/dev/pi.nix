{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.dev.pi = {
    enable = lib.mkEnableOption "pi coding agent CLI";
  };

  config = lib.mkIf config.user.dev.pi.enable {
    environment.systemPackages = [
      flakeInputs."pi-mono".packages."${pkgs.stdenv.hostPlatform.system}".default
    ];
  };
}
