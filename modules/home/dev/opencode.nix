{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.opencode;
in {
  options.home.dev.opencode = {
    enable = lib.mkEnableOption "OpenCode development tools";
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid.packages = with pkgs; [
      opencode
    ];
  };
}
