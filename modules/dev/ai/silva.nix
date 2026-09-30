{
  config,
  pkgs,
  flakeInputs,
  ...
}: let
  silva = flakeInputs.silva.packages.${pkgs.stdenv.hostPlatform.system};
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/silva"
    ".local/share/silva"
    ".local/state/silva"
  ];
  environment.systemPackages = [
    silva.silva-up
    silva.tui
    silva.kitty
  ];
}
