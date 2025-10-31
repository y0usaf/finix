{
  pkgs,
  config,
  ...
}: {
  home-manager.users.y0usaf = {
    launchd.agents.ssh-agent = {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.openssh}/bin/ssh-agent"
          "-D"
          "-a"
          "${config.user.homeDirectory}/.ssh/agent.sock"
        ];
        Sockets = {
          Listeners = {
            SockPathName = "${config.user.homeDirectory}/.ssh/agent.sock";
          };
        };
      };
    };

    home.sessionVariables = {
      SSH_AUTH_SOCK = "${config.user.homeDirectory}/.ssh/agent.sock";
    };
  };
}
