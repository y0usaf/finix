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
    ".local/state/guild"
  ];
  environment.systemPackages = [
    crest.crest-cli
    crest.crest-auth
    crest.crest-agent
    crest.crest-cell
    crest.guild
    crest.ouro
    crest.jev-review
  ];
}
