{
  config,
  pkgs,
  flakeInputs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/Leverage"
  ];
  environment.systemPackages = [
    flakeInputs.leverage.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
