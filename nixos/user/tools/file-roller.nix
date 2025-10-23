{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.tools.file-roller = {
    enable = lib.mkEnableOption "file-roller (archive manager)";
  };
  config = lib.mkIf config.user.tools.file-roller.enable {
    environment.systemPackages = [
      pkgs.file-roller
    ];
  };
}
