{config, ...}: let
  inherit (import ../../../../lib/ssh) hosts defaults;
  inherit (config) user;
  userName = user.name;
  identityFile = "${user.homeDirectory}/Tokens/id_rsa_${userName}";
in {
  home-manager.users."${userName}".programs.ssh = {
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
