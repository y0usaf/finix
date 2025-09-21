{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.quickshell;
in {
  options.home.ui.quickshell = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Quickshell desktop shell";
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      quickshell
      cava
    ];
  };
}
