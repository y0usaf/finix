{pkgs, ...}: {
  home-manager.users.y0usaf = {
    # SSH agent service via launchd
    launchd.agents.ssh-agent = {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.openssh}/bin/ssh-agent"
          "-D"
          "-a"
          "/Users/y0usaf/.ssh/agent.sock"
        ];
        Sockets = {
          Listeners = {
            SockPathName = "/Users/y0usaf/.ssh/agent.sock";
          };
        };
      };
    };

    # Set SSH_AUTH_SOCK environment variable
    home.sessionVariables = {
      SSH_AUTH_SOCK = "/Users/y0usaf/.ssh/agent.sock";
    };
  };
}
