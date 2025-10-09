{
  config,
  pkgs,
  lib,
  ...
}: let
  moreSpeeds = import ./moreSpeeds.nix {inherit config lib;};
  sources = import ./npins;
  availableMods = {
    steamodded = {
      src = sources.steamodded;
      name = "smods";
    };
    talisman = {
      src = sources.talisman;
      name = "Talisman";
    };
    cryptid = {
      src = sources.cryptid;
      name = "Cryptid";
    };
    multiplayer = {
      src = sources.multiplayer;
      name = "BalatroMultiplayer";
    };
    cardsleeves = {
      src = sources.cardsleeves;
      name = "CardSleeves";
    };
    jokerdisplay = {
      src = sources.jokerdisplay;
      name = "JokerDisplay-1.8.4.1";
    };
    pokermon = {
      src = sources.pokermon;
      name = "Pokermon";
    };
    stickersalwaysshown = {
      src = sources."Balatro-Stickers-Always-Shown";
      name = "StickersAlwaysShown";
    };
    handybalatro = {
      src = sources."HandyBalatro";
      name = "HandyBalatro";
    };
    aura = {
      src = sources."Aura";
      name = "Aura";
    };
  };
  enabledMods = lib.filterAttrs (name: _mod: lib.elem name config.home.gaming.balatro.enabledMods) availableMods;
  lovelyInjectorPackage = pkgs.fetchzip {
    url = "https://github.com/ethangreen-dev/lovely-injector/releases/download/v0.8.0/lovely-x86_64-pc-windows-msvc.zip";
    sha256 = "sha256-tFDiYDRW5arGz92Knug6XnyhxYatUQ7iR/Wxfz6Hjw4=";
    stripRoot = false;
  };
in {
  options.home.gaming.balatro = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Balatro mod management";
    };
    enableLovelyInjector = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable Lovely Injector - a runtime lua injector for LÖVE 2D games.
        This downloads and installs version.dll to enable mod loading in Balatro.
        Required for most Balatro mods to work.
      '';
    };
    enabledMods = lib.mkOption {
      type = lib.types.listOf (lib.types.enum ((lib.attrNames availableMods) ++ ["morespeeds"]));
      default = [];
      example = ["steamodded" "talisman" "cryptid" "multiplayer" "cardsleeves" "jokerdisplay" "pokermon" "stickersalwaysshown" "handybalatro" "aura" "morespeeds"];
      description = ''
        List of mod names to enable. Available mods:
        - steamodded: Steamodded/smods (core modding framework)
        - talisman: SpectralPack/Talisman
        - cryptid: SpectralPack/Cryptid
        - multiplayer: Balatro-Multiplayer/BalatroMultiplayer
        - cardsleeves: larswijn/CardSleeves
        - jokerdisplay: nh6574/JokerDisplay (shows joker calculations)
        - pokermon: InertSteak/Pokermon (Pokemon-themed jokers)
        - stickersalwaysshown: SirMaiquis/Balatro-Stickers-Always-Shown (keeps stickers visible on jokers)
        - handybalatro: SleepyG11/HandyBalatro (Quality of Life controls and shortcuts)
        - aura: SpectralPack/Aura (visual enhancement mod)
        - morespeeds: MoreSpeeds.lua (custom speed options)
      '';
    };
  };
  config = lib.mkMerge [
    moreSpeeds.config
    (lib.mkIf config.home.gaming.balatro.enable {
      usr.files =
        (lib.mapAttrs' (
            _name: mod:
              lib.nameValuePair
              ".local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods/${mod.name}"
              {
                clobber = true;
                source = mod.src;
              }
          )
          enabledMods)
        // (lib.optionalAttrs config.home.gaming.balatro.enableLovelyInjector {
          ".local/share/Steam/steamapps/common/Balatro/version.dll" = {
            clobber = true;
            source = "${lovelyInjectorPackage}/version.dll";
          };
        });
    })
  ];
}
