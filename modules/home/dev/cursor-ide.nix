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
    hjem.users.${config.user.name}.packages = with pkgs; [
      code-cursor
    ];
  };
}
