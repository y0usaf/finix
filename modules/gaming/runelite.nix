{
  config,
  lib,
  pkgs,
  ...
}: let
  runeliteScale = toString 2.0;
in {
  options.user.gaming.runelite.enable = lib.mkEnableOption "Bolt launcher for RuneLite";

  config = lib.mkIf config.user.gaming.runelite.enable {
    environment.systemPackages = [
      (pkgs.symlinkJoin {
        name = "bolt-launcher";
        paths = [pkgs.bolt-launcher];
        buildInputs = [pkgs.makeWrapper];
        postBuild = ''
          rm $out/bin/bolt-launcher
          makeWrapper ${pkgs.bolt-launcher}/bin/bolt-launcher $out/bin/bolt-launcher \
            --set GDK_DPI_SCALE ${runeliteScale} \
            --run 'export JDK_JAVA_OPTIONS="''${JDK_JAVA_OPTIONS:+$JDK_JAVA_OPTIONS }-Dsun.java2d.uiScale=${runeliteScale} -Dsun.java2d.uiScale.enabled=true"; export JAVA_TOOL_OPTIONS="''${JAVA_TOOL_OPTIONS:+$JAVA_TOOL_OPTIONS }-Dsun.java2d.uiScale=${runeliteScale} -Dsun.java2d.uiScale.enabled=true"'
        '';
      })
    ];
  };
}
