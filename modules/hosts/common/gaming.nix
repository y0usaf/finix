{lib, ...}: {
  user.gaming = {
    core.enable = lib.mkDefault true;
    controllers.enable = lib.mkDefault true;
    steam.enable = lib.mkDefault true;
    mangohud.enable = lib.mkDefault true;
    emulation = {
      wii-u.enable = lib.mkDefault true;
      gcn-wii.enable = lib.mkDefault true;
    };
    balatro = {
      enable = lib.mkDefault true;
      enableLovelyInjector = lib.mkDefault true;
      enabledMods = lib.mkDefault ["steamodded" "talisman" "cardsleeves" "multiplayer" "jokerdisplay" "pokermon" "aura" "stickersalwaysshown"];
    };
    wukong.enable = lib.mkDefault true;
    expedition33.enable = lib.mkDefault true;
    arc-raiders.enable = lib.mkDefault true;
  };
}
