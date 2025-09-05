{
  config,
  lib,
  ...
}: {
  options.home.programs.firefox = {
    enable = lib.mkEnableOption "Firefox browser with optimized settings";
  };
  options.home.programs.librewolf = {
    enable = lib.mkEnableOption "LibreWolf browser with optimized settings";
  };
}
