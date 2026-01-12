{config, ...}: let
  sharedSsh = import ../../../../lib/ssh;
  hosts = sharedSsh.hosts;
  defaults = sharedSsh.defaults;
  identityFile = "${config.user.homeDirectory}/Tokens/id_rsa_${config.user.name}";
in {
  home-manager.users.${config.user.name}.programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = defaults;

      "server" = {
        hostname = hosts.server.hostname;
        user = hosts.server.user;
      };

      "github.com" = {
        hostname = hosts.github.hostname;
        user = hosts.github.user;
        inherit identityFile;
      };

      "forgejo" = {
        hostname = hosts.forgejo.hostname;
        port = hosts.forgejo.port;
        user = hosts.forgejo.user;
        identitiesOnly = hosts.forgejo.identitiesOnly;
        inherit identityFile;
      };
    };
  };
}
