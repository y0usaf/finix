{lib, ...}: {
  user.shell = {
    rush.enable = lib.mkDefault true;
    cat-fetch.enable = lib.mkDefault true;
    ekko = {
      enable = lib.mkDefault true;
      autoStart = lib.mkDefault true;
      open = lib.mkDefault true;
      closeToNearestSession = lib.mkDefault true;
      openAttachesExisting = lib.mkDefault true;
    };
  };
}
