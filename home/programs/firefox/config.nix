{
  config,
  lib,
  ...
}: {
  options.home.programs.firefox = {
    enable = lib.mkEnableOption "Firefox browser with optimized settings";
  };
  config =
    lib.mkIf config.home.programs.firefox.enable {
    };
}
