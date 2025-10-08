{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home.ui.quickshell = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Quickshell desktop shell";
    };
  };
  config = lib.mkIf config.home.ui.quickshell.enable {
    environment.systemPackages = [
      pkgs.quickshell
      pkgs.cava
    ];
  };
}
