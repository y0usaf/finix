{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.dev.reasonix = {
    enable = lib.mkEnableOption "reasonix cache-first DeepSeek coding agent";
  };

  config = lib.mkIf config.user.dev.reasonix.enable {
    environment.systemPackages = [
      flakeInputs.reasonix-flake.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];
  };
}
