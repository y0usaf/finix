{
  config,
  lib,
  ...
}: let
  inherit (config) user;
  cfg = user.gaming.elden-ring;
  mods = user.gaming.mods.elden-ring;
  steamPath = lib.removePrefix "${user.homeDirectory}/" user.paths.steam.path;
  gameDir = "${steamPath}/steamapps/common/ELDEN RING/Game";
in {
  options.user.gaming.elden-ring = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Elden Ring configuration";
    };

    coop = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install Seamless Co-op into the game directory";
      };

      password = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Seamless Co-op session password (cooppassword)";
      };

      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Extra overrides merged into ersc_settings.ini (lowercase INI keys)";
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.coop.enable) {
    manzil.users."${user.name}".files = {
      "${gameDir}/ersc_launcher.exe" = {
        source = "${mods.SeamlessCoop.src}/ersc_launcher.exe";
      };

      "${gameDir}/SeamlessCoop/ersc.dll" = {
        source = "${mods.SeamlessCoop.src}/SeamlessCoop/ersc.dll";
      };

      "${gameDir}/SeamlessCoop/crashpad/crashpad_handler.exe" = {
        source = "${mods.SeamlessCoop.src}/SeamlessCoop/crashpad/crashpad_handler.exe";
      };

      "${gameDir}/SeamlessCoop/locale/english.json" = {
        source = "${mods.SeamlessCoop.src}/SeamlessCoop/locale/english.json";
      };

      "${gameDir}/SeamlessCoop/ersc_settings.ini" = {
        generator = lib.generators.toINI {};
        value = lib.recursiveUpdate {
          "GAMEPLAY" = {
            allow_invaders = 0;
            death_debuffs = 1;
            allow_summons = 1;
            overhead_player_display = 0;
            skip_splash_screens = 1;
            append_steam_id_to_players = 0;
            always_spectate_on_death = 0;
            default_boot_master_volume = 5;
          };
          "SCALING" = {
            enemy_health_scaling = 35;
            enemy_damage_scaling = 0;
            enemy_posture_scaling = 15;
            boss_health_scaling = 100;
            boss_damage_scaling = 0;
            boss_posture_scaling = 20;
          };
          "PASSWORD" = {
            cooppassword = cfg.coop.password;
          };
          "SAVE" = {
            save_file_extension = "co2";
          };
          "LANGUAGE" = {
            mod_language_override = "";
          };
        } cfg.coop.settings;
      };
    };
  };
}
