{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.cursor-ide;
in {
  options.home.dev.cursor-ide = {
    enable = lib.mkEnableOption "Cursor IDE";
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid.packages = with pkgs; [
      code-cursor
    ];
  };
}
