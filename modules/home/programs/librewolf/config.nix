{
  config,
  lib,
  ...
}: {
  options.home.programs.librewolf = {
    enable = lib.mkEnableOption "LibreWolf browser with optimized settings";
  };
  config =
    lib.mkIf config.home.programs.librewolf.enable {
    };
}
