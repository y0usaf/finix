#===============================================================================
#                          🖥️ NixOS Configuration 🖥️
#===============================================================================
# 🔧 Core system settings
# 📦 Package management
# 🛠️ Hardware configuration
# 🔒 Security settings
# 👤 User environment
# 🚀 Services & programs
# 🌐 Network & virtualization
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

  #── 🔧 Core System Settings ──────────────#
  system.stateVersion = globals.stateVersion; # Do not change this value
  time.timeZone = globals.timezone;
  networking.hostName = globals.hostname;

  #── 📦 Package Management ─────────────────#
  nixpkgs.config.allowUnfree = true;

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
    # Enable flakes and new commands
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  #── 🛠️ Hardware Configuration ────────────#
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = ["kvm-amd"];
    extraModulePackages = [];
  };

  # Graphics & Display
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

  services.xserver.videoDrivers = ["nvidia"];

  # Audio Configuration
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  #── 🔒 Security & Permissions ────────────#
  security = {
    polkit = {
      enable = true;
      # Allow nvidia-smi without password
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.policykit.exec" &&
              action.lookup("command_line").indexOf("nvidia-smi") >= 0) {
              return polkit.Result.YES;
          }
        });
      '';
    };
    # Sudo rules
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

  environment.systemPackages = with pkgs; [
    # Basic utilities
    git
    vim
    curl
    wget
    cachix
    unzip
    lm_sensors
    yt-dlp-light
    bash
    # Python with packages
    (python3.withPackages (ps:
      with ps; [
        pip
        setuptools
      ]))
    python3
  ];

  #── 🚀 Services & Programs ───────────────#
  # XDG Portal Configuration
  xdg.portal = {
    enable = true;
    wlr.enable = false;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common.default = ["hyprland"];
      hyprland = {
        default = ["hyprland"];
        "org.freedesktop.impl.portal.Screenshot" = ["hyprland"];
        "org.freedesktop.impl.portal.Screencast" = ["hyprland"];
      };
    };
  };

  # Shell Configuration
  programs = {
    zsh = {
      enable = false;
      enableGlobalCompInit = false;
    };
    dconf.enable = true;
  };

  services.dbus.packages = [pkgs.dconf];

  # Device Rules
  services.udev.extraRules = ''
    # Vial rules for non-root access to keyboards
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", TAG+="uaccess"
  '';

  #── 🌐 Network & Virtualization ─────────#
  networking.networkmanager.enable = true;
  virtualisation.lxd.enable = true;
}
