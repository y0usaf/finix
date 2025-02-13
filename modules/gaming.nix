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
  config = lib.mkIf (builtins.elem "gaming" profile.features) {
    home.activation.debugGamingConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "Gaming config path: ${gaming-config}"
      ls -la ${gaming-config}/marvel-rivals/
      ls -la ${gaming-config}/wukong/
    '';

    # Gaming-related packages
    home.packages = with pkgs; [
      steam
      protonup-qt
      gamemode
      protontricks
      prismlauncher
    ];

    home.file = {
      # Marvel Rivals configurations
      ".local/share/Steam/steamapps/compatdata/2767030/pfx/drive_c/users/steamuser/AppData/Local/Marvel/Saved/Config/Windows/GameUserSettings.ini".source = "${gaming-config}/marvel-rivals/GameUserSettings.ini";

      ".local/share/Steam/steamapps/compatdata/2767030/pfx/drive_c/users/steamuser/AppData/Local/Marvel/Saved/Config/Windows/Engine.ini".source = "${gaming-config}/marvel-rivals/Engine.ini";

      # Wukong configuration
      ".local/share/Steam/steamapps/compatdata/2358720/pfx/drive_c/users/steamuser/AppData/Local/b1/Saved/Config/Windows/Engine.ini".source = "${gaming-config}/wukong/Engine.ini";
    };
  };
}
