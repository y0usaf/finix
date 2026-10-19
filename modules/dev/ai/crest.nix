{
  config,
  pkgs,
  flakeInputs,
  ...
}: let
  crest = flakeInputs.crest.packages.${pkgs.stdenv.hostPlatform.system};
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".local/state/ouro"
  ];
  environment.systemPackages = [
    crest.crest-cli
    crest.crest-auth
    crest.crest-agent
    crest.crest-cell
    crest.ouro
    crest.jev-review
  ];
}
