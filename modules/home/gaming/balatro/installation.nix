{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.gaming.balatro;
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
    morespeeds = {
      name = "MoreSpeeds.lua";
    };
  };
  enabledMods = lib.filterAttrs (name: _mod: lib.elem name cfg.enabledMods && name != "morespeeds") availableMods;
  lovelyInjectorPackage = pkgs.fetchzip {
    url = "https://github.com/ethangreen-dev/lovely-injector/releases/download/v0.7.1/lovely-x86_64-pc-windows-msvc.zip";
    sha256 = "sha256-KjWSJugIfUOfWHZctEDKWGvNERXDzjW1+Ty5kJtEJlw=";
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
      type = lib.types.listOf (lib.types.enum (lib.attrNames availableMods));
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
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid.file.home =
      (lib.optionalAttrs (lib.elem "morespeeds" cfg.enabledMods) {
        ".local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods/MoreSpeeds.lua".text = ''
          --- STEAMODDED HEADER
          --- MOD_NAME: More Speed
          --- MOD_ID: MoreSpeed
          --- MOD_AUTHOR: [Steamo]
          --- MOD_DESCRIPTION: More Speed options!
          --- This mod is deprecated, use Nopeus instead: https://github.com/jenwalter666/JensBalatroCollection/tree/main/Nopeus
          ----------------------------------------------
          ------------MOD CODE -------------------------
          local setting_tabRef = G.UIDEF.settings_tab
          function G.UIDEF.settings_tab(tab)
              local setting_tab = setting_tabRef(tab)
              if tab == 'Game' then
                  local speeds = create_option_cycle({label = localize('b_set_gamespeed'), scale = 0.8, options = {0.25, 0.5, 1, 2, 3, 4, 8, 16, 32, 64, 128, 1000}, opt_callback = 'change_gamespeed', current_option = (
                      G.SETTINGS.GAMESPEED == 0.25 and 1 or
                      G.SETTINGS.GAMESPEED == 0.5 and 2 or
                      G.SETTINGS.GAMESPEED == 1 and 3 or
                      G.SETTINGS.GAMESPEED == 2 and 4 or
                      G.SETTINGS.GAMESPEED == 3 and 5 or
                      G.SETTINGS.GAMESPEED == 4 and 6 or
                      G.SETTINGS.GAMESPEED == 8 and 7 or
                      G.SETTINGS.GAMESPEED == 16 and 8 or
                      G.SETTINGS.GAMESPEED == 32 and 9 or
                      G.SETTINGS.GAMESPEED == 64 and 10 or
                      G.SETTINGS.GAMESPEED == 128 and 11 or
                      G.SETTINGS.GAMESPEED == 1000 and 12 or
                      3 -- Default to 1 if none match, adjust as necessary
                  )})
                  local free_speed_text = {
                      n = G.UIT.R,
                      config = {
                          align = "cm",
                          id = "free_speed_text"
                      },
                      nodes = {
                          {
                              n = G.UIT.T,
                              config = {
                                  align = "cm",
          						scale = 0.3 * 1.5,
          						text = "Free Speed",
          						colour = G.C.UI.TEXT_LIGHT
                              }
                          }
                      }
                  }
                  local free_speed_box = {
                      n = G.UIT.R,
                      config = {
                          align = "cm",
                          padding = 0.05,
                          id = "free_speed_box"
                      },
                      nodes = {
                          create_text_input({
                              hooked_colour = G.C.RED,
                              colour = G.C.RED,
                              all_caps = true,
                              align = "cm",
                              w = 2,
                              max_length = 4,
                              prompt_text = 'Custom Speed',
                              ref_table = G.SETTINGS.COMP,
                              ref_value = 'name'
                          })
                      }
                  }
                  setting_tab.nodes[1] = speeds
                  -- TODO fix this
                  --table.insert(setting_tab.nodes, 2, free_speed_text)
                  --table.insert(setting_tab.nodes, 3, free_speed_box)
              end
              return setting_tab
          end
          ----------------------------------------------
          ------------MOD CODE END----------------------
        '';
      })
      // (lib.mapAttrs' (
          name: mod:
            lib.nameValuePair
            ".local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods/${mod.name}"
            {source = mod.src;}
        )
        enabledMods)
      // (lib.optionalAttrs cfg.enableLovelyInjector {
        ".local/share/Steam/steamapps/common/Balatro/version.dll".source = "${lovelyInjectorPackage}/version.dll";
      });
  };
}
