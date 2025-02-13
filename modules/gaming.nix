#================================================================================
#                                modules/gaming.nix
#      🎮 Gaming Configuration
#================================================================================
# 🎯 Steam settings
# 🎮 Gaming packages
# 🔧 Performance tweaks
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  gaming-config,
  ...
}: {
  config = {
    # Gaming-related packages
    home.packages = with pkgs; [
      steam
      protonup-qt
      gamemode
      protontricks
      prismlauncher
    ];

    home.file = {
      # -------------------------------------------------------------------------
      # Marvel Rivals: GameUserSettings.ini file in the Marvel folder
      # -------------------------------------------------------------------------
      ".local/share/Steam/steamapps/compatdata/2767030/pfx/drive_c/users/steamuser/AppData/Local/Marvel/Saved/Config/Windows/GameUserSettings.ini" = {
        source = "${gaming-config}/marvel-rivals/GameUserSettings.ini";
      };

      # -------------------------------------------------------------------------
      # Marvel Rivals: Engine.ini file in the Marvel folder
      # -------------------------------------------------------------------------
      ".local/share/Steam/steamapps/compatdata/2767030/pfx/drive_c/users/steamuser/AppData/Local/Marvel/Saved/Config/Windows/Engine.ini" = {
        source = "${gaming-config}/marvel-rivals/Engine.ini";
      };

      # -------------------------------------------------------------------------
      # Wukong: Engine.ini file in its designated folder
      # -------------------------------------------------------------------------
      ".local/share/Steam/steamapps/compatdata/2358720/pfx/drive_c/users/steamuser/AppData/Local/b1/Saved/Config/Windows/Engine.ini" = {
        source = "${gaming-config}/wukong/Engine.ini";
      };
    };
  };
}
