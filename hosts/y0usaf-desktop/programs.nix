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
      model = "large-v3-turbo";
      binds = false; # bolo owns Alt+M / Mod+m
    };
    bolo = {
      enable = true;
      autofill = true;
      provider = "cuda";
      # Words Parakeet cannot know: my projects and handles. Aliases are
      # only non-words (a real-word alias like "echo" would hijack normal
      # speech); undeclared mishearings fall through to fuzzy matching.
      vocabulary = {
        Hyprland = ["hyper land" "hipper land"];
        niri = ["neary" "nyree"];
        y0usaf = ["you sef" "yousef" "you saf"];
        "sherpa-onnx" = ["sherpa onyx" "sherpa onix"];
        tomoe = ["toe moe" "tomo eh"];
        ekko = ["eck oh" "eh ko"];
        moon = [];
        finix = ["fee nix" "finnix" "fi nix"];
      };
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
