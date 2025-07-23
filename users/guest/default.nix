_: {
  # User system configuration
  system = {
    isNormalUser = true;
    shell = "zsh";
    extraGroups = ["networkmanager" "video" "audio"];
    homeDirectory = "/home/guest";
  };
  core = {
    packages.enable = true;
    defaults = {
      browser = "firefox";
      editor = "nvim";
      terminal = "foot";
      fileManager = "pcmanfm";
      launcher = "foot -a 'launcher' ~/.config/scripts/sway-launcher-desktop.sh";
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
    music.path = "/home/guest/Music";
    dcim.path = "/home/guest/DCIM";
  };
  ui = {
    cursor.enable = true;
    fonts.enable = true;
    foot.enable = true;
    gtk.enable = true;
    hyprland = {
      enable = true;
      flake.enable = true;
      hy3.enable = false;
    };
    wayland.enable = true;
  };
  programs = {
    firefox.enable = true;
    media.enable = true;
    imv.enable = true;
    mpv.enable = true;
    pcmanfm.enable = true;
  };
  shell = {
    zsh.enable = true;
    cat-fetch.enable = true;
  };
  tools = {
    "7z".enable = true;
    file-roller.enable = true;
  };
  services = {
    polkitAgent.enable = true;
  };
}
