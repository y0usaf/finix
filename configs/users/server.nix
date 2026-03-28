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
    hashedPasswordFile = "/persist/secrets/password-hashes/y0usaf";
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
      KbdInteractiveAuthentication = false;
    };
  };

  user = {
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
    paths = {
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
      cat-fetch.enable = true;
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
      ssh.enable = true;
      syncthing = {
        enable = true;

        devices = import ../syncthing-devices.nix;

        folders = {
          tokens = {
            id = "bv79n-fh4kx";
            label = "Tokens";
            path = "~/Tokens";
            devices = ["desktop" "laptop" "server" "phone"];
            type = "receiveonly";
          };
          music = {
            id = "oty33-aq3dt";
            label = "Music";
            path = "~/Music";
            devices = ["desktop" "server" "phone"];
            type = "receiveonly";
          };
          dcim = {
            id = "ti9yk-zu3xs";
            label = "DCIM";
            path = "~/DCIM";
            devices = ["desktop" "server" "phone"];
            type = "receiveonly";
          };
          pictures = {
            id = "zbxzv-35v4e";
            label = "Pictures";
            path = "~/Pictures";
            devices = ["desktop" "server" "phone"];
            type = "receiveonly";
          };
        };
      };
    };
  };
}
