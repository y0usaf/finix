{
  lib,
  pkgs,
  ...
}: {
  user.ui = {
    cudaterm.enable = true;
    tomoe = {
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
      settings.honor-xdg-activation-with-invalid-serial = true;
    };
  };
}
