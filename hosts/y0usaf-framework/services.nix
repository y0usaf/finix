_: {
  user.services = {
    ssh.enable = true;
    polkitAgent.enable = true;
    syncthing = {
      enable = true;
      enabledFolders = ["tokens"];
    };
  };
}
