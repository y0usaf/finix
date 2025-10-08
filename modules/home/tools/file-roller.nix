{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home.tools.file-roller = {
    enable = lib.mkEnableOption "file-roller (archive manager)";
  };
  config = lib.mkIf config.home.tools.file-roller.enable {
    environment.systemPackages = [
      pkgs.file-roller
    ];
  };
}
