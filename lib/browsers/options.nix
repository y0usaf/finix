{lib, ...}: {
  options.user.programs.firefox = {
    enable = lib.mkEnableOption "Firefox browser";
  };
  options.user.programs.librewolf = {
    enable = lib.mkEnableOption "LibreWolf browser";
  };
}
