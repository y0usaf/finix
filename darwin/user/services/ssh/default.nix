{config, ...}: let
  sharedSsh = import ../../../../lib/ssh;
  inherit (sharedSsh) hosts;
  inherit (sharedSsh) defaults;
  identityFile = "${config.user.homeDirectory}/Tokens/id_rsa_${config.user.name}";
in {
  home-manager.users.${config.user.name}.programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = defaults;

      "server" = {
        inherit (hosts.server) hostname user forwardAgent;
      };

      "github.com" = {
        inherit (hosts.github) hostname user forwardAgent;
        inherit identityFile;
      };

      "forgejo" = {
        inherit (hosts.forgejo) hostname;
        inherit (hosts.forgejo) port;
        inherit (hosts.forgejo) user;
        inherit (hosts.forgejo) identitiesOnly;
        inherit identityFile;
      };
    };
  };
}
