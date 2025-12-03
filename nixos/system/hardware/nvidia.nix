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
    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = false; # useless on wayland
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };

    hardware.graphics.extraPackages =
      [
        pkgs.nvidia-vaapi-driver
      ]
      ++ lib.optionals config.hardware.nvidia.cuda.enable [
        pkgs.cudatoolkit
      ];

    boot = {
      # Early KMS for proper initialization
      initrd.kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
      blacklistedKernelModules = ["nouveau"];
      kernelParams = [
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
        "nvidia.NVreg_UsePageAttributeTable=1"
        "nvidia.NVreg_EnableResizableBar=1"
        "nvidia.NVreg_RegistryDwords=RmEnableAggressiveVblank=1"
        "nvidia_modeset.disable_vrr_memclk_switch=1"
      ];
    };

    environment = {
      systemPackages = lib.optionals config.hardware.nvidia.cuda.enable [
        pkgs.cudaPackages.cudnn
      ];
      sessionVariables = {
        # Disable vsync for lower latency
        __GL_SYNC_TO_VBLANK = "0";
        # Enable VRR/GSync
        __GL_VRR_ALLOWED = "1";
        # Lower frame buffering for latency
        __GL_MaxFramesAllowed = "1";
        __GL_YIELD = "usleep";
        CUDA_CACHE_PATH = "$XDG_CACHE_HOME/nv";
        CUDA_DISABLE_PERF_BOOST = "1";
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
      # Fix high VRAM usage on electron apps
      etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool.json".text = builtins.toJSON {
        rules =
          map (proc: {
            pattern = {
              feature = "procname";
              matches = proc;
            };
            profile = "No VidMem Reuse";
          }) [
            "Hyprland"
            ".Hyprland-wrapped"
            "niri"
            "Discord"
            ".Discord-wrapped"
            "DiscordCanary"
            ".DiscordCanary-wrapped"
            "electron"
            ".electron-wrapped"
            "firefox"
            ".firefox-wrapped"
            "chromium"
            "librewolf"
            ".librewolf-wrapped"
          ];
      };
    };

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
