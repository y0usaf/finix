{lib, ...}: {
  user.shell = {
    rush.enable = lib.mkDefault true;
    cat-fetch.enable = lib.mkDefault true;
    ekko = {
      enable = lib.mkDefault true;
      autoStart = lib.mkDefault true;
      open = lib.mkDefault true;
    };
  };
}
