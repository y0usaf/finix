{config, ...}: let
  inherit (import ../../../../lib/ssh) hosts defaults;
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
        inherit (hosts.forgejo) hostname port user identitiesOnly;
        inherit identityFile;
      };
    };
  };
}
