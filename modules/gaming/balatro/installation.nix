{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.user) gaming;
  mods = gaming.mods.balatro;

  availableMods = {
    steamodded = {
      src = mods.steamodded;
      name = "smods";
    };
    talisman = {
      src = mods.talisman;
      name = "Talisman";
    };
    cryptid = {
      src = mods.cryptid;
      name = "Cryptid";
    };
    multiplayer = {
      src = mods.multiplayer;
      name = "BalatroMultiplayer";
    };
    cardsleeves = {
      src = mods.cardsleeves;
      name = "CardSleeves";
    };
    jokerdisplay = {
      src = mods.jokerdisplay;
      name = "JokerDisplay-1.8.4.1";
    };
    pokermon = {
      src = mods.pokermon;
      name = "Pokermon";
    };
    stickersalwaysshown = {
      src = mods."Balatro-Stickers-Always-Shown";
      name = "StickersAlwaysShown";
    };
    handybalatro = {
      src = mods."HandyBalatro";
      name = "HandyBalatro";
    };
    aura = {
      src = mods."Aura";
      name = "Aura";
    };
  };

  inherit (lib) types mkOption;
  typeBool = types.bool;
in {
  options.user.gaming.balatro = {
    enable = mkOption {
      type = typeBool;
      default = false;
      description = "Enable Balatro mod management";
    };
    enableLovelyInjector = mkOption {
      type = typeBool;
      default = false;
      description = ''
        Enable Lovely Injector - a runtime lua injector for LÖVE 2D games.
        This downloads and installs version.dll to enable mod loading in Balatro.
        Required for most Balatro mods to work.
      '';
    };
    enabledMods = mkOption {
      type = types.listOf (types.enum ((lib.attrNames availableMods) ++ ["morespeeds"]));
      default = [];
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
        - ultimatespeedup: sse2/balatro-ultimate-speedup-mod (additional speed options)
        - morespeeds: MoreSpeeds.lua (custom speed options)
      '';
    };
  };
  config = lib.mkMerge [
    (import ./moreSpeeds.nix {inherit config lib;}).config
    (lib.mkIf gaming.balatro.enable (let
      inherit (config) user;
      steamPath = lib.removePrefix "${user.homeDirectory}/" user.paths.steam.path;
      balatroCfg = user.gaming.balatro;
    in {
      manzil.users."${config.user.name}".files =
        (lib.mapAttrs' (
            _: mod:
              lib.nameValuePair
              "${steamPath}/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods/${mod.name}"
              {
                source = mod.src;
              }
          )
          (lib.filterAttrs (name: _: lib.elem name balatroCfg.enabledMods) availableMods))
        // (lib.optionalAttrs balatroCfg.enableLovelyInjector {
          "${steamPath}/steamapps/common/Balatro/version.dll" = {
            source = "${pkgs.fetchzip {
              url = "https://github.com/ethangreen-dev/lovely-injector/releases/download/v0.8.0/lovely-x86_64-pc-windows-msvc.zip";
              sha256 = "sha256-tFDiYDRW5arGz92Knug6XnyhxYatUQ7iR/Wxfz6Hjw4=";
              stripRoot = false;
            }}/version.dll";
          };
        });
    }))
  ];
}
