{lib, ...}: {
  user.services = {
    ssh.enable = lib.mkDefault true;
    polkitAgent.enable = lib.mkDefault true;
    syncthing.enable = lib.mkDefault true;
  };
}
