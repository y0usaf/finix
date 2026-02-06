{
  defaults = {
    forwardAgent = false;
    extraOptions = {
      AddKeysToAgent = "yes";
      ServerAliveInterval = "60";
      ServerAliveCountMax = "5";
      ControlMaster = "auto";
      ControlPersist = "10m";
      SetEnv = "TERM=xterm-256color";
    };
  };

  hosts = {
    server = {
      hostname = "192.168.2.66";
      user = "y0usaf";
      forwardAgent = true;
    };

    github = {
      hostname = "github.com";
      user = "git";
      forwardAgent = true;
    };

    forgejo = {
      hostname = "y0usaf-server";
      port = 2222;
      user = "forgejo";
      identitiesOnly = true;
    };
  };
}
