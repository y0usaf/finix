{
  config,
  lib,
  pkgs,
  ...
}: {
  user = {
    appearance = {
      dpi = 109;
      termFontSize = 16;
      hyprcursorSize = 36;
    };

    paths.wallpapers = "${config.user.homeDirectory}/DCIM/Wallpapers/32_9/";

    ui.tomoe = {
      displays = {
        "DP-4" = {
          mode = [5120 1440];
          icc = "${pkgs.runCommand "ls49ag95.icc" {} "${lib.getExe' pkgs.colord "cd-create-profile"} -o $out ${./ls49ag95.iccprofile.xml}"}";
        };
        "HDMI-A-2" = {
          mode = [1920 1080 60];
          position = [5120 0];
        };
      };

      bar.modules = ["cpu" "memory" "gpu" "time" "date"];
    };

    gaming = {
      p4g.enable = true;
      solo-leveling-arise.enable = true;
      aethermancer.enable = true;
      elden-ring.enable = true;
      proton.enable = true;
      runelite.enable = true;
    };

    tools."3d-printing".enable = true;
  };
}
