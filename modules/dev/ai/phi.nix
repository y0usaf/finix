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
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".config/phi"
      ".local/share/phi"
      ".phi"
    ];
    environment.systemPackages = [
      flakeInputs.phi.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];
  };
}
