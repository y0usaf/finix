{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.quickshell;
  username = config.user.name;
in {
  options.home.ui.quickshell = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Quickshell desktop shell";
    };
  };
  config = lib.mkIf cfg.enable {
    # Desktop shell packages installed at system level
    environment.systemPackages = with pkgs; [
      quickshell
      cava
    ];
  };
}
