{lib, ...}: {
  options.user.programs.firefox = {
    enable = lib.mkEnableOption "Firefox browser with optimized settings";
  };
  options.user.programs.librewolf = {
    enable = lib.mkEnableOption "LibreWolf browser with optimized settings";
  };
}
