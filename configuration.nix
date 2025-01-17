#─────────────────────── 🛠️  NIXOS CORE CONFIG ───────────────────────#
# ⚠️  Root access required | System rebuild needed for changes        #
#──────────────────────────────────────────────────────────────────────#
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

  #── 🔧 System Core ─────────────────────────#
  time.timeZone = globals.timezone;
  networking.hostName = globals.hostname;
  system.stateVersion = globals.stateVersion;

  #── 📦 Nix & Packages ──────────────────────#
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

  #── 🔄 Boot & Hardware ─────────────────────#
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = ["kvm-amd"];
    extraModulePackages = [];
  };

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

  #── 🔊 Audio ─────────────────────────────#
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  #── 🖥️ Desktop ───────────────────────────#
  services.xserver.videoDrivers = ["nvidia"];

  #── 🛡️ Security ──────────────────────────#
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

  #── 🌍 Environment ────────────────────────#
  # Core utils, dev tools, containers, archives
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

  #── 👤 User Management ───────────────────#
  # Account, permissions, groups
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

  #── 🔐 Sudo Rules ────────────────────────#
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

  #── 🌐 Services ──────────────────────────#
  networking.networkmanager.enable = true;

  # XDG Desktop Portal
  xdg.portal = {
    enable = true;
    wlr.enable = false;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
    config = {
      common = {
        default = ["hyprland" "gtk"];
      };
      hyprland = {
        default = ["hyprland" "gtk"];
      };
    };
  };

  programs.zsh = {
    enable = false;
    enableGlobalCompInit = false;
  };

  #── 📱 Udev Rules ────────────────────────#
  services.udev.extraRules = ''
    # Vial rules for non-root access to keyboards
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", TAG+="uaccess"
  '';

  #── 💻 Virtualization ──────────────────────#
  virtualisation = {
    lxd.enable = true;
  };
}
