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
  inputs,  # Add inputs to get access to gaming-config
  ...
}: let
  # Create a derivation for the gaming configs
  gamingConfigPackage = pkgs.stdenv.mkDerivation {
    pname = "gaming-config";
    version = "1.0";
    src = inputs.gaming-config;

    installPhase = ''
      echo "Current directory: $PWD"
      echo "Source directory: $src"
      
      # Create the directory structure
      mkdir -p $out/{marvel-rivals,wukong}
      
      echo "Listing source directory contents:"
      ls -la $src
      
      echo "Listing marvel-rivals directory contents:"
      ls -la $src/marvel-rivals || echo "marvel-rivals directory not found"
      
      # Install Marvel Rivals configs
      for file in GameUserSettings.ini Engine.ini; do
        if [ -f "$src/marvel-rivals/$file" ]; then
          echo "Copying $file..."
          cp -v "$src/marvel-rivals/$file" "$out/marvel-rivals/"
        else
          echo "Warning: $file not found, creating empty file"
          touch "$out/marvel-rivals/$file"
        fi
      done

      # Install Wukong config
      if [ -f "$src/wukong/Engine.ini" ]; then
        echo "Copying Wukong Engine.ini..."
        cp -v "$src/wukong/Engine.ini" "$out/wukong/"
      else
        echo "Warning: Wukong Engine.ini not found, creating empty file"
        touch "$out/wukong/Engine.ini"
      fi

      echo "Final output directory contents:"
      find $out -type f -ls
    '';
  };
in {
  config = lib.mkIf (builtins.elem "gaming" profile.features) {
    home.activation.debugGamingConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "Gaming config package path: ${gamingConfigPackage}"
      echo "Directory contents:"
      find ${gamingConfigPackage} -type f -ls
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
      ".local/share/Steam/steamapps/compatdata/2767030/pfx/drive_c/users/steamuser/AppData/Local/Marvel/Saved/Config/Windows/GameUserSettings.ini".source = "${gamingConfigPackage}/marvel-rivals/GameUserSettings.ini";

      ".local/share/Steam/steamapps/compatdata/2767030/pfx/drive_c/users/steamuser/AppData/Local/Marvel/Saved/Config/Windows/Engine.ini".source = "${gamingConfigPackage}/marvel-rivals/Engine.ini";

      # Wukong configuration
      ".local/share/Steam/steamapps/compatdata/2358720/pfx/drive_c/users/steamuser/AppData/Local/b1/Saved/Config/Windows/Engine.ini".source = "${gamingConfigPackage}/wukong/Engine.ini";
    };
  };
}
