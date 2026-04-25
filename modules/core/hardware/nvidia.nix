{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) optionals;
  nvidiaHw = config.hardware.nvidia;
  isOpen = nvidiaHw.open;
in {
  options = {
    hardware.nvidia.enable = lib.mkEnableOption "NVIDIA GPU support";
  };

  config = lib.mkIf nvidiaHw.enable {
    services.xserver.videoDrivers = ["nvidia"];

    nixpkgs.config.cudaSupport = true;

    hardware = {
      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = !isOpen;
        open = true;
        gsp.enable = isOpen;
        nvidiaSettings = false; # useless on wayland
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "595.45.04";
          sha256_64bit = "sha256-zUllSSRsuio7dSkcbBTuxF+dN12d6jEPE0WgGvVOj14=";
          openSha256 = "sha256-uqNfImwTKhK8gncUdP1TPp0D6Gog4MSeIJMZQiJWDoE=";
          usePersistenced = false;
          useSettings = false;
        };
      };
      graphics.extraPackages = [
        pkgs.nvidia-vaapi-driver
        pkgs.cudatoolkit
      ];
    };

    boot = {
      # Early KMS for proper initialization
      initrd.kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
      blacklistedKernelModules = ["nouveau"];
      kernelParams =
        [
          "nvidia.NVreg_UsePageAttributeTable=1"
          "nvidia.NVreg_EnableResizableBar=1"
          "nvidia.NVreg_RegistryDwords=RmEnableAggressiveVblank=1"
          "nvidia_modeset.disable_vrr_memclk_switch=1"
        ]
        ++ optionals isOpen [
          "nvidia.NVreg_UseKernelSuspendNotifiers=1"
        ]
        ++ optionals (!isOpen) [
          "nvidia.NVreg_TemporaryFilePath=/var/tmp"
        ];
    };

    environment = {
      systemPackages = [
        pkgs.cudaPackages.cudnn
      ];
      sessionVariables = {
        __GL_SYNC_TO_VBLANK = "0";
        __GL_VRR_ALLOWED = "1";
        __GL_MaxFramesAllowed = "1";
        __GL_YIELD = "usleep";
        #__EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json";
        #__EGL_EXTERNAL_PLATFORM_CONFIG_DIRS = "/run/opengl-driver/share/egl/egl_external_platform.d";
        CUDA_CACHE_PATH = "${config.user.homeDirectory}/.cache/nv";
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
        rules = [
          {
            pattern = {
              feature = "true";
              matches = "";
            };
            profile = "No VidMem Reuse";
          }
          {
            pattern = {
              feature = "true";
              matches = "";
            };
            profile = "CudaNoStablePerfLimit";
          }
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
