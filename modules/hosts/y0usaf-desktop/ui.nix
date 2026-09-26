{lib, ...}: {
  user.ui = {
    cudaterm.enable = true;
    monstar.enable = lib.mkForce false;
    tomoe = {
      displays = {
        "DP-4".mode = [5120 1440];
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
