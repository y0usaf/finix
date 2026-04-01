{lib, ...}: {
  user.defaults = {
    editor = lib.mkDefault "nvim";
    terminal = lib.mkDefault "foot";
    browser = lib.mkDefault "firefox";
  };
}
