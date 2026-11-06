{inputPackages, ...}: let
  inherit (inputPackages) crest;
in {
  user.persist.directories = [
    ".local/state/ouro"
    ".local/state/guild"
    ".local/state/crest-auth"
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
