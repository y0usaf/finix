_: {
  # User system configuration
  system = {
    isNormalUser = true;
    shell = "zsh";
    extraGroups = ["wheel" "networkmanager" "video" "audio" "input" "gamemode" "dialout" "bluetooth" "lp" "docker"];
    homeDirectory = "/home/y0usaf";
  };
  core = {
    packages.enable = true;
    defaults = {
      browser = "firefox";
      editor = "nvim";
      ide = "cursor";
      terminal = "foot";
      fileManager = "pcmanfm";
      launcher = "foot -a 'launcher' ~/.config/scripts/sway-launcher-desktop.sh";
      discord = "discord-canary";
      archiveManager = "7z";
      imageViewer = "imv";
      mediaPlayer = "mpv";
    };
    fonts.preset = "fast-mono";
    appearance = {
      enable = true;
      dpi = 109;
      baseFontSize = 12;
      cursorSize = 36;
    };
    user.enable = true;
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
    gtk.enable = true;
    hyprland = {
      enable = true;
      flake.enable = true;
      hy3.enable = false;
    };
    quickshell.enable = true;
    wallust.enable = true;
    wayland.enable = true;
  };
  programs = {
    vesktop.enable = true;
    webapps.enable = true;
    firefox.enable = true;
    discord.enable = true;
    obsidian.enable = true;
    creative.enable = true;
    media.enable = true;
    bluetooth.enable = true;
    obs.enable = true;
    bambu.enable = true;
    imv.enable = true;
    mpv.enable = true;
    pcmanfm.enable = true;
    qbittorrent.enable = true;
    sway-launcher-desktop.enable = true;
  };
  dev = {
    claude-code.enable = true;
    claude-code-router.enable = true;
    gemini-cli.enable = true;
    mcp.enable = true;
    docker.enable = true;
    nvim = {
      enable = true;
      neovide = false;
    };
    python.enable = true;
    repomix.enable = true;
    opencode.enable = true;
    latex.enable = true;
  };
  shell = {
    zsh.enable = true;
    cat-fetch.enable = true;
    zellij.enable = true;
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
    nixosGitSync = {
      enable = true;
      remoteBranch = "main";
    };
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
      enabledMods = ["steamodded" "talisman" "morespeeds" "cardsleeves" "multiplayer" "jokerdisplay" "pokermon" "aura" "handybalatro" "stickersalwaysshown"];
    };
    wukong = {
      enable = true;
    };
  };
}
