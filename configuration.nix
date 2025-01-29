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
  globals,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./env.nix
    ./cachix.nix
  ];

  config = {
    #── 🔧 Core System Settings ─────────────────#
    system.stateVersion = globals.stateVersion;
    time.timeZone = globals.timezone;
    networking.hostName = globals.hostname;
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
        trusted-users = ["root" globals.username];
        builders-use-substitutes = true;
        fallback = true;
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
      kernelPackages = pkgs.linuxPackages_latest;
      kernelModules = [
        "kvm-amd"
        "k10temp"
        "nct6775"
      ];
    };

    hardware = {
      nvidia = lib.mkIf globals.enableNvidia {
        modesetting.enable = true;
        powerManagement.enable = true;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      i2c.enable = true;
    };

    services = {
      xserver.videoDrivers = lib.mkIf globals.enableNvidia ["nvidia"];

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

      dbus.enable = true;
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
          users = [globals.username];
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
    users.users.${globals.username} = {
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
        ++ lib.optionals globals.enableGaming [
          "gamemode"
        ];
      ignoreShellProgramCheck = true;
    };

    #── 🌐 Network & Virtualization ─────────#
    networking.networkmanager.enable = true;
    virtualisation.lxd.enable = true;

    #── 🚀 Core Services ──────────────────#
    services.udev.extraRules = ''
      # Vial rules for n/on-root access to keyboards
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", TAG+="uaccess"
    '';
  };
}
