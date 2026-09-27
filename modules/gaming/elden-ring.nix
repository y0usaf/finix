{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) user;
  seamlessCoop = pkgs.fetchzip {
    url = "https://github.com/yuiamoroll/EldenRingSeamlessCoopRelease/releases/download/v1.9.8/Seamless.Co-op.v1.9.8-510-1-9-8-1776128433.zip";
    sha256 = "sha256-Bz2EFv+kUXaZY2vb66RsqOb6n4kZkGp/49xh5/SgTHc=";
    stripRoot = false;
  };
  gameDir = "${lib.removePrefix "${user.homeDirectory}/" user.paths.steam}/steamapps/common/ELDEN RING/Game";
in {
  options.user.gaming.elden-ring.enable = lib.mkEnableOption "Elden Ring configuration";

  config = lib.mkIf user.gaming.elden-ring.enable {
    manzil.users."${user.name}".files = {
      "${gameDir}/ersc_launcher.exe" = {
        source = "${seamlessCoop}/ersc_launcher.exe";
      };

      "${gameDir}/SeamlessCoop/ersc.dll" = {
        source = "${seamlessCoop}/SeamlessCoop/ersc.dll";
      };

      "${gameDir}/SeamlessCoop/crashpad/crashpad_handler.exe" = {
        source = "${seamlessCoop}/SeamlessCoop/crashpad/crashpad_handler.exe";
      };

      "${gameDir}/SeamlessCoop/locale/english.json" = {
        source = "${seamlessCoop}/SeamlessCoop/locale/english.json";
      };

      "${gameDir}/SeamlessCoop/ersc_settings.ini" = {
        generator = lib.generators.toINI {};
        value = {
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
            cooppassword = "ShopKeeper";
          };
          "SAVE" = {
            save_file_extension = "co2";
          };
          "LANGUAGE" = {
            mod_language_override = "";
          };
        };
      };
    };
  };
}
