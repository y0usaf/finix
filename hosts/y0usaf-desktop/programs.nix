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
    asryx = {
      enable = true;
      backend = "cuda";
      autofill = true;
    };
    obsidian.enable = true;
    creative.enable = true;
    media.enable = true;
    cmus.enable = true;
    bluetooth.enable = true;
    obs = {
      enable = true;
      backgroundRemoval.enable = false;
    };
    imv.enable = true;
    mimeapps.enable = true;
    mpv.enable = true;
    pcmanfm.enable = true;
    qbittorrent.enable = true;
    rudo.enable = true;
    stremio.enable = true;
    tui-launcher.enable = true;
    slack.enable = true;
    stoat-desktop.enable = true;
    btop.enable = true;
  };
}
