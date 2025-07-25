{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.tools.file-roller;
in {
  options.home.tools.file-roller = {
    enable = lib.mkEnableOption "file-roller (archive manager)";
  };
  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.maid.packages = with pkgs; [
      file-roller
    ];
  };
}
