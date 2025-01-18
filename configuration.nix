#===============================================================================
#                       🛠️ NixOS Core Configuration 🛠️
#===============================================================================
# 🔧 System settings
# 📦 Package management
# 🔄 Boot configuration
# 🎮 Hardware settings
# 🔊 Audio setup
# 👤 User management
# 🔐 Security rules
# 🌐 Network services
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

  #── 🔧 System Core ─────────────────────────────────────────#
  time.timeZone = globals.timezone;
  networking.hostName = globals.hostname;
  system.stateVersion = globals.stateVersion;

  #── 📦 Nix & Package Management ────────────────────────────#
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0;
      system-features = ["big-parallel" "kvm" "nixos-test"];
      sandbox = true;
      trusted-users = ["root" "y0usaf"];
      builders-use-substitutes = true;
      fallback = true;
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  #── 🔄 Boot & Hardware Configuration ──────────────────────#
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = ["kvm-amd"];
    extraModulePackages = [];
  };

  #── 🎮 Hardware Settings ─────────────────────────────────#
  hardware = {
    nvidia = {
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
  };

  #── 🔊 Audio Configuration ───────────────────────────────#
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  #── 🖥️ Display Settings ─────────────────────────────────#
  services.xserver.videoDrivers = ["nvidia"];

  #── 🛡️ Security & Permissions ──────────────────────────#
  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.policykit.exec" &&
            action.lookup("command_line").indexOf("nvidia-smi") >= 0) {
            return polkit.Result.YES;
        }
      });
    '';
  };

  #── 🌍 System Environment ────────────────────────────────#
  environment = {
    systemPackages = with pkgs; [
      git
      vim
      curl
      wget
      cachix
      (python3.withPackages (ps:
        with ps; [
          pip
          setuptools
        ]))
      python3
      unzip
    ];
  };

  #── 👤 User Management ───────────────────────────────────#
  users.users.${globals.username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "gamemode"
      "input"
    ];
    ignoreShellProgramCheck = true;
  };

  #── 🔐 Sudo Configuration ─────────────────────────────────#
  security.sudo.extraRules = [
    {
      users = ["y0usaf"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  #── 🌐 Network Services ──────────────────────────────────#
  networking.networkmanager.enable = true;

  #── 🚀 Desktop Portal Services ─────────────────────────────#
  xdg.portal = {
    enable = true;
    wlr.enable = false;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = ["hyprland"];
      };
      hyprland = {
        default = ["hyprland"];
        "org.freedesktop.impl.portal.Screenshot" = ["hyprland"];
        "org.freedesktop.impl.portal.Screencast" = ["hyprland"];
      };
    };
  };

  #── 🐚 Shell Configuration ────────────────────────────────#
  programs.zsh = {
    enable = false;
    enableGlobalCompInit = false;
  };

  #── 📱 Device Rules ──────────────────────────────────────#
  services.udev.extraRules = ''
    # Vial rules for non-root access to keyboards
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", TAG+="uaccess"
  '';

  #── 💻 Virtualization Support ─────────────────────────────#
  virtualisation = {
    lxd.enable = true;
  };
}
