{
  pkgs,
  lib,
  ...
}: {
  users.users.y0usaf = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["wheel" "networkmanager" "docker"];
    home = "/home/y0usaf";
    ignoreShellProgramCheck = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6ZHkn1pACV406TM5yUCRt/874vybgpUW3sUKka9nAC y0usaf@y0usaf-desktop"
    ];
  };

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

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    openFirewall = true;
  };

  home = {
    core = {
      packages.enable = true;
      user = {
        enable = true;
      };
      defaults = {
        editor = lib.mkDefault "nvim";
        terminal = lib.mkDefault "foot";
        browser = lib.mkDefault "firefox";
        discord = lib.mkDefault "discord";
        fileManager = lib.mkDefault "pcmanfm";
        mediaPlayer = lib.mkDefault "mpv";
        imageViewer = lib.mkDefault "imv";
        archiveManager = lib.mkDefault "file-roller";
        launcher = lib.mkDefault "foot";
        ide = lib.mkDefault "nvim";
      };
    };
    directories = {
      flake.path = "/home/y0usaf/nixos";
    };
    dev = {
      nvim = {
        enable = true;
        neovide = false;
      };
      docker.enable = true;
    };
    shell = {
      zsh.enable = true;
      aliases.enable = true;
      zellij = {
        enable = true;
        autoStart = false;
      };
    };
    tools = {
      git = {
        enable = true;
        name = "y0usaf";
        email = "OA99@Outlook.com";
      };
      nh = {
        enable = true;
        flake = "/home/y0usaf/nixos";
      };
      "7z".enable = true;
    };
    services = {
      formatNix.enable = true;
    };
  };
}
