{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.gaming.mangohud;
in {
  options.gaming.mangohud = {
    enable = lib.mkEnableOption "MangoHud";
    enableSessionWide = lib.mkEnableOption "MangoHud for all Vulkan apps";
    refreshRate = lib.mkOption {
      type = lib.types.int;
      default = 170;
      description = "Target refresh rate for FPS limiting";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.mangohud];

    environment.sessionVariables = lib.mkIf cfg.enableSessionWide {
      MANGOHUD = "1";
    };
  };
}
