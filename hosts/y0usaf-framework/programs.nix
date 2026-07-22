_: {
  user.programs = {
    webapps.enable = true;
    librewolf.enable = true;
    codex-desktop = {
      # 2026-07-22: upstream Codex.dmg (mutable URL) now ships ChatGPT.app;
      # codex-desktop-flake can't extract it and the June dmg fell out of
      # every local store. Re-enable once the flake handles the new layout.
      enable = false;
      yoloMode = true;
    };
    discord = {
      stable.enable = true;

      vesktop.enable = true;
    };
    handy = {
      enable = true;
      transcribeBinding = "alt_left+m";
    };
    obsidian.enable = true;
    creative.enable = false;
    media.enable = false;
    cmus.enable = false;
    bluetooth.enable = true;
    obs = {
      enable = false;
      backgroundRemoval.enable = false;
    };
    imv.enable = true;
    mimeapps.enable = true;
    mpv.enable = true;
    pcmanfm.enable = true;
    qbittorrent.enable = false;
    rudo.enable = true;
    stremio.enable = true;
    tui-launcher.enable = true;
    slack.enable = true;
    stoat-desktop.enable = false;
    btop.enable = true;
  };
}
