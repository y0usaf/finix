{
  pkgs,
  lib,
  ...
}: {
  # Direct NixOS user configuration
  users.users.y0usaf = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["wheel" "networkmanager" "video" "audio" "input" "gamemode" "dialout" "bluetooth" "lp" "docker"];
    home = "/home/y0usaf";
    ignoreShellProgramCheck = true;
  };
  home = {
    core = {
      packages.enable = true;
      user = {
        enable = true;
        bookmarks = [
          "file:///home/y0usaf/Downloads Downloads"
          "file:///home/y0usaf/Documents Documents"
          "file:///home/y0usaf/Music Music"
          "file:///home/y0usaf/DCIM Pictures"
          "file:///home/y0usaf/nixos NixOS"
          "file:///tmp tmp"
        ];
      };
      defaults = {
        browser = "librewolf";
        editor = lib.mkDefault "nvim";
        ide = lib.mkDefault "cursor";
        terminal = lib.mkDefault "foot";
        fileManager = lib.mkDefault "pcmanfm";
        launcher = lib.mkDefault "foot -a 'launcher' ~/.config/scripts/sway-launcher-desktop.sh";
        discord = lib.mkDefault "discord-canary";
        archiveManager = lib.mkDefault "file-roller";
        imageViewer = lib.mkDefault "imv";
        mediaPlayer = lib.mkDefault "mpv";
      };
      appearance = {
        enable = true;
        dpi = 144;
        baseFontSize = 12;
        cursorSize = 18;
        opacity = 0.7;
        fonts = {
          main = [
            {
              package = pkgs.fastFonts;
              name = "Fast IosevkaSlab";
            }
          ];
          fallback = [
            {
              package = pkgs.noto-fonts-emoji;
              name = "Noto Color Emoji";
            }
            {
              package = pkgs.noto-fonts-cjk-sans;
              name = "Noto Sans CJK";
            }
            {
              package = pkgs.font-awesome;
              name = "Font Awesome";
            }
          ];
        };
      };
    };
    directories = {
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
    };
    ui = {
      ags.enable = true;
      cursor.enable = true;
      fonts.enable = true;
      foot.enable = true;
      gtk = {
        enable = true;
        scale = 1.5;
      };
      hyprland = {
        enable = false;
      };
      niri = {
        enable = true;
        extraConfig = ''
          window-rule {
            match app-id="foot"
            opacity 1.0
          }

          window-rule {
            match app-id="launcher"
            open-floating true
          }
        '';
      };
      quickshell.enable = true;
      wallust.enable = true;
      wayland.enable = true;
    };
    programs = {
      vesktop.enable = true;
      webapps.enable = true;
      librewolf.enable = true;
      discord.enable = true;
      obsidian.enable = true;
      creative.enable = true;
      media.enable = true;
      bluetooth.enable = true;
      obs.enable = true;
      imv.enable = true;
      mimeapps.enable = true;
      mpv.enable = true;
      pcmanfm.enable = true;
      qbittorrent.enable = true;
      stremio.enable = true;
      sway-launcher-desktop.enable = true;
    };
    dev = {
      claude-code.enable = true;

      gemini-cli.enable = true;
      mcp.enable = true;
      docker.enable = true;
      nvim = {
        enable = true;
        neovide = false;
      };
      python.enable = true;
      opencode = {
        enable = true;
        enableMcpServers = true;
      };
      latex.enable = false;
      upscale.enable = true;
    };
    shell = {
      zsh.enable = true;
      aliases.enable = true;
      cat-fetch.enable = true;
      zellij = {
        enable = true;
        autoStart = true;
      };
    };
    tools = {
      git = {
        enable = true;
        name = "y0usaf";
        email = "OA99@Outlook.com";
        nixos-git-sync = {
          enable = true;
          nixosRepoUrl = "git@github.com:y0usaf/nixos.git";
          remoteBranch = "main";
        };
      };
      jj = {
        enable = true;
        name = "y0usaf";
        email = "OA99@Outlook.com";
      };
      nh = {
        enable = true; # Re-enabled with minimal flake wrapper
        flake = "/home/y0usaf/nixos";
      };
      npins-build = {
        enable = true;
      };
      "7z".enable = true;
      file-roller.enable = true;
      spotdl.enable = true;
      yt-dlp.enable = true;
    };
    services = {
      polkitAgent.enable = true;
      formatNix.enable = true;
      syncthing.enable = true;
    };
    gaming = {
      core.enable = true;
      controllers.enable = true;
      emulation = {
        wii-u.enable = true;
        gcn-wii.enable = true;
      };
      marvel-rivals = {
        engine.enable = true;
        gameusersettings.enable = true;
        marvelusersettings.enable = true;
      };
      balatro = {
        enable = true;
        enableLovelyInjector = true;
        enabledMods = ["steamodded" "talisman" "morespeeds" "cardsleeves" "multiplayer" "jokerdisplay" "pokermon" "aura" "stickersalwaysshown"];
      };
      wukong = {
        enable = true;
      };
    };
  };
}
