{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    hardware.nvidia = {
      enable = lib.mkEnableOption "NVIDIA GPU support";
      cuda.enable = lib.mkEnableOption "CUDA support";
    };
  };

  config = lib.mkIf config.hardware.nvidia.enable {
    boot.kernelParams = [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    hardware.graphics.extraPackages = lib.optionals config.hardware.nvidia.cuda.enable [
      pkgs.cudatoolkit
    ];
    environment = {
      systemPackages = lib.optionals config.hardware.nvidia.cuda.enable [
        pkgs.cudaPackages.cudnn
      ];
      etc = {
        "nvidia/nvidia-application-profiles-rc".text = lib.mkForce ''
          {
            "rules": [
              {
                "pattern": {
                  "feature": "procname",
                  "matches": ".Hyprland-wrapped"
                },
                "profile": "No VidMem Reuse"
              },
              {
                "pattern": {
                  "feature": "procname",
                  "matches": "niri"
                },
                "profile": "No VidMem Reuse"
              },
              {
                "pattern": {
                  "feature": "procname",
                  "matches": "electron"
                },
                "profile": "No VidMem Reuse"
              },
              {
                "pattern": {
                  "feature": "procname",
                  "matches": ".firefox-wrapped"
                },
                "profile": "No VidMem Reuse"
              },
              {
                "pattern": {
                  "feature": "procname",
                  "matches": "firefox"
                },
                "profile": "No VidMem Reuse"
              }
            ]
          }
        '';
      };
      variables = {
        GBM_BACKEND = "nvidia-drm";
        LIBVA_DRIVER_NAME = "nvidia";
        WLR_NO_HARDWARE_CURSORS = "1";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        NVIDIA_DRIVER_CAPABILITIES = "all";
        WAYDROID_EXTRA_ARGS = "--gpu-mode host";
        GALLIUM_DRIVER = "nvidia";
        LIBGL_DRIVER_NAME = "nvidia";
      };
    };
    services.xserver.videoDrivers = ["nvidia"];
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.policykit.exec" &&
            action.lookup("command_line").indexOf("nvidia-smi") >= 0) {
            return polkit.Result.YES;
        }
      });
    '';
  };
}
