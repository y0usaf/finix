{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.gaming.runelite;
  runeliteScale = toString cfg.scale;
  boltLauncherPackage =
    if cfg.scale == 1.0
    then pkgs.bolt-launcher
    else
      pkgs.symlinkJoin {
        name = "bolt-launcher";
        paths = [pkgs.bolt-launcher];
        buildInputs = [pkgs.makeWrapper];
        postBuild = ''
          rm $out/bin/bolt-launcher
          makeWrapper ${pkgs.bolt-launcher}/bin/bolt-launcher $out/bin/bolt-launcher \
            --set GDK_DPI_SCALE ${runeliteScale} \
            --run 'export JDK_JAVA_OPTIONS="''${JDK_JAVA_OPTIONS:+$JDK_JAVA_OPTIONS }-Dsun.java2d.uiScale=${runeliteScale} -Dsun.java2d.uiScale.enabled=true"; export JAVA_TOOL_OPTIONS="''${JAVA_TOOL_OPTIONS:+$JAVA_TOOL_OPTIONS }-Dsun.java2d.uiScale=${runeliteScale} -Dsun.java2d.uiScale.enabled=true"'
        '';
      };
in {
  options.user.gaming.runelite = {
    enable = lib.mkEnableOption "Bolt launcher for RuneLite";
    scale = lib.mkOption {
      type = lib.types.float;
      default = config.user.ui.gtk.scale;
      description = "RuneLite/Bolt UI scale factor";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [boltLauncherPackage];
  };
}
