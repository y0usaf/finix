{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.gaming.runelite = {
    enable = lib.mkEnableOption "RuneLite";
  };
  config = lib.mkIf config.user.gaming.runelite.enable {
    environment.systemPackages = [
      pkgs.runelite
    ];
  };
}
