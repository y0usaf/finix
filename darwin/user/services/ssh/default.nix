{config, ...}: {
  imports = [
    ./ssh-agent.nix
  ];

  home-manager.users.y0usaf.programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        forwardAgent = true;
        addKeysToAgent = "yes";
        serverAliveInterval = 60;
        serverAliveCountMax = 5;
        controlMaster = "auto";
        controlPath = "%d/.ssh/master-%r@%h:%p";
        controlPersist = "10m";
        setEnv = {
          TERM = "xterm-256color";
        };
      };

      "server" = {
        hostname = "192.168.2.66";
        user = "y0usaf";
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "${config.user.homeDirectory}/Tokens/id_rsa_y0usaf";
      };

      "forgejo" = {
        hostname = "y0usaf-server";
        port = 2222;
        user = "forgejo";
        identityFile = "${config.user.homeDirectory}/Tokens/id_rsa_y0usaf";
        identitiesOnly = true;
      };
    };
  };
}
