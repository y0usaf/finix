{
  config,
  pkgs,
  flakeInputs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/phi"
    ".local/share/phi"
    ".phi"
  ];
  environment.systemPackages = [
    flakeInputs.phi.packages."${pkgs.stdenv.hostPlatform.system}".default
  ];
}
