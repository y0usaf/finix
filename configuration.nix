#===============================================================================
#                          🖥️ NixOS Configuration 🖥️
#===============================================================================
# 🔧 Core system settings
# 📦 Package management
# 🛠️ Hardware configuration
# 🔒 Security settings
#
# ⚠️  Root access required | System rebuild needed for changes
#===============================================================================
{
  config,
  lib,
  pkgs,
  profile,
  inputs,
  ...
}: let
  enableNvidia = builtins.elem "nvidia" profile.features;
  enableWayland = builtins.elem "wayland" profile.features;
  enableHyprland = builtins.elem "hyprland" profile.features;
  enableGaming = builtins.elem "gaming" profile.features;
in {
  imports = [
    ./hardware-configuration.nix
    ./modules/env.nix
  ];

  config = {
    #── 🔧 Core System Settings ─────────────────#
    system.stateVersion = profile.stateVersion;
    time.timeZone = profile.timezone;
    networking.hostName = profile.hostname;
    nixpkgs.config.allowUnfree = true;

    #── 📦 Nix Package Management ──────────────#
    nix = {
      package = pkgs.nixVersions.stable;
      settings = {
        auto-optimise-store = true;
        max-jobs = "auto";
        cores = 0;
        system-features = ["big-parallel" "kvm" "nixos-test"];
        sandbox = true;
        trusted-users = ["root" profile.username];
        builders-use-substitutes = true;
        fallback = true;

        # Added from cachix.nix
        substituters = [
          "https://cache.nixos.org"
          "https://hyprland.cachix.org"
          "https://chaotic-nyx.cachix.org"
          "https://nyx.cachix.org"
          "https://cuda-maintainers.cachix.org"
          "https://nix-community.cachix.org"
          "https://nix-gaming.cachix.org"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
          "nyx.cachix.org-1:xH6G0MO9PrpeGe7mHBtj1WbNzmnXr7jId2mCiq6hipE="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        ];
      };
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };

    #── 🛠️ Hardware & Boot Configuration ───────#
    boot = {
      loader = {
        systemd-boot = {
          enable = true;
          configurationLimit = 20;
        };
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };
      };
      kernelPackages = pkgs.linuxPackages_cachyos;
      kernelModules = [
        "kvm-amd"
        "k10temp"
        "nct6775"
      ];
    };

    hardware = {
      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "570.86.16";
          sha256_64bit = "sha256-RWPqS7ZUJH9JEAWlfHLGdqrNlavhaR1xMyzs8lJhy9U=";
          openSha256 = "sha256-DuVNA63+pJ8IB7Tw2gM4HbwlOh1bcDg2AN2mbEU9VPE=";
          settingsSha256 = "sha256-9rtqh64TyhDF5fFAYiWl3oDHzKJqyOW3abpcf2iNRT8=";
          usePersistenced = false;
        };
      };
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      i2c.enable = true;
    };

    services = {
      xserver.videoDrivers = lib.mkIf enableNvidia ["nvidia"];

      #── 🔊 Audio Configuration ────────────────#
      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
      };

      #── ⚙️ SCX Service Configuration ──────────#
      scx = {
        enable = true;
        scheduler = "scx_lavd";
        package = pkgs.scx.rustscheds;
      };

      dbus = {
        enable = true;
        packages = [
          pkgs.dconf
          pkgs.gcr
        ];
      };

      udev.extraRules = ''
        # Vial rules for n/on-root access to keyboards
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users"
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", TAG+="uaccess"
      '';
    };

    #── 🔒 Security & Permissions ────────────#
    security = {
      rtkit.enable = true;
      polkit.enable = true;
      polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.policykit.exec" &&
              action.lookup("command_line").indexOf("nvidia-smi") >= 0) {
              return polkit.Result.YES;
          }
        });
      '';
      sudo.extraRules = [
        {
          users = [profile.username];
          commands = [
            {
              command = "ALL";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
    };

    #── 👤 User Environment ─────────────────#
    programs = {
      hyprland = lib.mkIf (builtins.elem "wayland" profile.features && builtins.elem "hyprland" profile.features) {
        enable = true;
        xwayland.enable = true;
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      };
    };

    users.users.${profile.username} = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups =
        [
          "wheel"
          "networkmanager"
          "video"
          "audio"
          "input"
        ]
        ++ lib.optionals enableGaming [
          "gamemode"
        ];
      ignoreShellProgramCheck = true;
    };

    #── 🌐 Network & Virtualization ─────────#
    networking.networkmanager.enable = true;
    virtualisation.lxd.enable = true;

    #── 🚀 Core Services ──────────────────#
    xdg.portal = lib.mkIf (builtins.elem "wayland" profile.features) {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
      config = {
        common = {
          default = ["gtk"];
          "org.freedesktop.impl.portal.OpenURI" = ["gtk"];
        };
      };
    };
  };
}
