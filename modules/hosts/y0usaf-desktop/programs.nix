_: {
  user.programs = {
    grok-bot.enable = true;
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
    creative.enable = true;
    media.enable = true;
    cmus.enable = true;
    obs = {
      enable = true;
      backgroundRemoval.enable = true;
    };
    qbittorrent.enable = true;
    stoat-desktop.enable = true;
  };
}
