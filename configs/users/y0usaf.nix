{
  pkgs,
  lib,
  config,
  flakeInputs,
  system,
  ...
}: {
  users.users.y0usaf = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["wheel" "networkmanager" "video" "audio" "input" "gamemode" "dialout" "bluetooth" "lp" "docker"];
    home = "/home/y0usaf";
    ignoreShellProgramCheck = true;
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
  user = {
    defaults = {
      browser = "librewolf";
      editor = lib.mkDefault "nvim";
      ide = lib.mkDefault "cursor";
      terminal = lib.mkDefault "foot";
      fileManager = lib.mkDefault "pcmanfm";
      launcher = lib.mkDefault "foot -a 'launcher' ~/.config/scripts/tui-launcher.sh";
      discord = lib.mkDefault "discord";
      archiveManager = lib.mkDefault "file-roller";
      imageViewer = lib.mkDefault "imv";
      mediaPlayer = lib.mkDefault "mpv";
    };
    appearance = {
      dpi = 144;
      baseFontSize = 12;
      cursorSize = 18;
      opacity = 0.7;
    };
    paths = {
      flake.path = "/home/y0usaf/nixos";
      music.path = "/home/y0usaf/Music";
      dcim.path = "/home/y0usaf/DCIM";
      steam = {
        path = "/home/y0usaf/.local/share/Steam";
        create = false;
      };
      wallpapers = {
        static.path = "/home/y0usaf/DCIM/Wallpapers/32_9";
        video.path = "/home/y0usaf/DCIM/Wallpapers_Video";
      };
      bookmarks = [
        "file:///home/y0usaf/Downloads Downloads"
        "file:///home/y0usaf/Documents Documents"
        "file:///home/y0usaf/Music Music"
        "file:///home/y0usaf/DCIM Pictures"
        "file:///home/y0usaf/nixos NixOS"
        "file:///tmp tmp"
      ];
    };
    ui = {
      ags.enable = true;
      cursor.enable = true;
      fonts = {
        enable = true;
        mainFont = flakeInputs.fast-fonts.packages.${system}.default;
        mainFontName = "Iosevka Term Slab";
        backup = {
          package = pkgs.noto-fonts-cjk-sans;
          name = "Noto Sans CJK";
        };
      };
      foot.enable = true;
      gtk = {
        enable = true;
        scale = 1.5;
      };
      hyprland = {
        enable = true;
      };
      mangowc.enable = false;
      niri = {
        enable = true;
        extraConfig = ''
          window-rule {
            match app-id="launcher"
            open-floating true
          }
        '';
      };
      vicinae.enable = true;
      quickshell.enable = true;
      wayland.enable = true;
    };
    programs = {
      webapps.enable = true;
      librewolf.enable = true;
      discord = {
        stable.enable = true;
        vesktop.enable = true;
      };
      obsidian.enable = true;
      creative.enable = true;
      media.enable = true;
      cmus.enable = true;
      bluetooth.enable = true;
      obs.enable = true;
      imv.enable = true;
      mimeapps.enable = true;
      mpv.enable = true;
      pcmanfm.enable = true;
      qbittorrent.enable = true;
      stremio.enable = true;
      tui-launcher.enable = true;
      slack.enable = true;
    };
    dev = {
      claude-code.enable = true;
      codex.enable = true;
      crush.enable = true;
      gemini-cli.enable = true;
      mcp.enable = true;
      docker.enable = true;
      gcloud.enable = true;
      localllama.enable = true;
      nvim = {
        enable = true;
        neovide = false;
      };
      python.enable = true;
      opencode = {
        enable = true;
        enableMcpServers = true;
      };
      latex.enable = true;
      upscale.enable = true;
    };
    shell = {
      zsh.enable = true;
      cat-fetch.enable = true;
      zellij = {
        enable = true;
        autoStart = false;
        zjstatus.enable = true;
      };
    };
    tools = {
      git = {
        enable = true;
        name = "y0usaf";
        email = "OA99@Outlook.com";
      };
      gh.enable = true;
      nh = {
        enable = true;
        flake = "/home/y0usaf/nixos";
      };
      "7z".enable = true;
      file-roller.enable = true;
      spotdl.enable = true;
      yt-dlp.enable = true;
    };
    services = {
      ssh.enable = true;
      polkitAgent.enable = true;
      formatNix.enable = true;
      udiskie.enable = true;
      syncthing = {
        enable = true;
        devices = {
          desktop = {
            id = "KII4S2Y-KWA6M4K-MCQAUOO-C6PMX4L-V5JVDPW-HHZF52D-HP57BNH-EKCCZQC";
          };
          laptop = {
            id = "EAHAPON-XKBJVGI-44SGTXR-WU6BF5U-WZKHJXS-7QNTBHQ-D4ICOVA-I346HQ7";
          };
          server = {
            id = "GY3T3SL-3JOOX3I-2SE72PF-V6ZSTIE-QI4EIYK-OBL6IDV-4IWLDDG-VM2ATAG";
          };
          phone = {
            id = "JYAIN4T-MXQYDAP-2M6CSKX-KKRYVJC-5GMSRYP-LSZRRRV-QSOWY7W-YNQGOAC";
            compression = "never";
          };
        };

        folders =
          {
            tokens = {
              id = "bv79n-fh4kx";
              label = "Tokens";
              path = "~/Tokens";
              devices = ["desktop" "laptop" "server" "phone"];
            };
          }
          // lib.optionalAttrs (config.networking.hostName == "y0usaf-desktop") {
            music = {
              id = "oty33-aq3dt";
              label = "Music";
              path = "~/Music";
              devices = ["desktop" "server" "phone"];
            };
            dcim = {
              id = "ti9yk-zu3xs";
              label = "DCIM";
              path = "~/DCIM";
              devices = ["desktop" "server" "phone"];
            };
            pictures = {
              id = "zbxzv-35v4e";
              label = "Pictures";
              path = "~/Pictures";
              devices = ["desktop" "server" "phone"];
            };
          };
      };
    };
    gaming = {
      core.enable = true;
      controllers.enable = true;
      steam.enable = true;
      mangohud.enable = true;
      emulation = {
        wii-u.enable = true;
        gcn-wii.enable = true;
      };
      balatro = {
        enable = true;
        enableLovelyInjector = true;
        enabledMods = ["steamodded" "talisman" "morespeeds" "cardsleeves" "multiplayer" "jokerdisplay" "pokermon" "aura" "stickersalwaysshown"];
      };
      wukong = {
        enable = true;
      };
      expedition33 = {
        gameusersettings.enable = true;
        clairobscurfix.enable = true;
        engine.enable = true;
      };
      duet-night-abyss = {
        enable = true;
      };
      arc-raiders = {
        enable = true;
      };
    };
  };
}
