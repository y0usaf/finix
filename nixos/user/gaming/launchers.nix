{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.gaming.launchers = {
    lutris.enable = lib.mkEnableOption "Lutris user configuration";
    heroic.enable = lib.mkEnableOption "Heroic user configuration";
  };

  config = {
    usr = lib.mkMerge [
      (lib.mkIf config.user.gaming.launchers.lutris.enable (
        lib.optionalAttrs config.gaming.proton.enable {
          xdg.data.files."lutris/runners/proton/GE-Proton".source = "${pkgs.proton-ge-bin}/steamcompattool";
        }
      ))

      (lib.mkIf config.user.gaming.launchers.heroic.enable (
        lib.optionalAttrs config.gaming.proton.enable {
          xdg.config.files."heroic/tools/proton/GE-Proton".source = "${pkgs.proton-ge-bin}/steamcompattool";
        }
      ))
    ];
  };
}
