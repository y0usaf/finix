{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.user) gaming;
  fetchGitHub = owner: repo: rev: hash:
    pkgs.fetchFromGitHub {inherit owner repo rev hash;};

  availableMods = {
    steamodded = {
      src = fetchGitHub "Steamodded" "smods" "9bb34e88cbc7d3122944baa038a7b2e5bb3efd10" "sha256-Z+BngswINBGz9XWZ7uhJNr0RmnK63J4LLyXDIEA2LNQ=";
      name = "smods";
    };
    talisman = {
      src = fetchGitHub "SpectralPack" "Talisman" "372d66c64bf987987cffbe31f731b3d1732526f3" "sha256-xvEeSHS8wkj7UxvEJ8KYWB7CE9ToHPgXO652XBuJ1j0=";
      name = "Talisman";
    };
    multiplayer = {
      src = fetchGitHub "Balatro-Multiplayer" "BalatroMultiplayer" "c7b1c210f0d6699819222b1767ee9469878d1c52" "sha256-rEHQ7DJd66gE7+5fTmnuBMUngv32W5qYbHgSU9EdIyw=";
      name = "BalatroMultiplayer";
    };
    cardsleeves = {
      src = fetchGitHub "larswijn" "CardSleeves" "c2a22f091fe92d1bcbd547297a837791b6eae771" "sha256-pf0E320SK3LHJ2rZfgKJBXFY0LjNrPVyQv5M+jecedk=";
      name = "CardSleeves";
    };
    jokerdisplay = {
      src = fetchGitHub "nh6574" "JokerDisplay" "7d7a61761b13894820270f9664d33685f54ec82a" "sha256-Iia+vkXOtRPmo3X+w7PFvB9P8N1jDYpHYr4cKGkmXnQ=";
      name = "JokerDisplay-1.8.4.1";
    };
    pokermon = {
      src = fetchGitHub "InertSteak" "Pokermon" "98a06f49be978052bc74a6cba80b08d38f607fd2" "sha256-zkdKh7zBsLDQ9NOcYJnE0mSBA/hbiSeI3w7fFsSyEb8=";
      name = "Pokermon";
    };
    stickersalwaysshown = {
      src = fetchGitHub "SirMaiquis" "Balatro-Stickers-Always-Shown" "v1.4.0" "sha256-raCsA7E7JpFjoc6/gGzpRnP7r/3lU9W3rgc9L4BdTT8=";
      name = "StickersAlwaysShown";
    };
    aura = {
      src = fetchGitHub "SpectralPack" "Aura" "dbb6496d163d15e86b0afb6879d32b891164af05" "sha256-4WHbRAUCHGtU/MwJeSQX9NdS7TX6zlsTffxl43f0JJA=";
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
      type = types.listOf (types.enum (lib.attrNames availableMods));
      default = [];
      description = ''
        List of mod names to enable. Available mods:
        - steamodded: Steamodded/smods (core modding framework)
        - talisman: SpectralPack/Talisman
        - multiplayer: Balatro-Multiplayer/BalatroMultiplayer
        - cardsleeves: larswijn/CardSleeves
        - jokerdisplay: nh6574/JokerDisplay (shows joker calculations)
        - pokermon: InertSteak/Pokermon (Pokemon-themed jokers)
        - stickersalwaysshown: SirMaiquis/Balatro-Stickers-Always-Shown (keeps stickers visible on jokers)
        - aura: SpectralPack/Aura (visual enhancement mod)
      '';
    };
  };
  config = lib.mkMerge [
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
