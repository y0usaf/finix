{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.siyuan = {
    enable = lib.mkEnableOption "Siyuan module";
  };

  config = lib.mkIf config.user.programs.siyuan.enable {
    environment.systemPackages = [pkgs.siyuan];
  };
}
