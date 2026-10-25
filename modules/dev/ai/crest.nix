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
    crest.crest-web
    crest.crest-agent
    crest.crest-cell
    crest.crest-map
    crest.crest-mcp
    crest.crest-mux
    crest.muntin
    crest.guild
    crest.ouro
    crest.jev-review
  ];
}
