###############################################################################
# Gaming Mods Module
# Handles symlinks for mod files and game configurations
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.gaming;
in {
  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Configuration Files and Mods
    ###########################################################################
    home.activation.symlinkGameConfigFiles = let
      # Base directories
      configDir = "${config.home.homeDirectory}/nixos/lib/resources/gaming-config";
      steamDir = "$HOME/.local/share/Steam";

      # Marvel Rivals paths
      mrConfigDir = "${configDir}/marvel-rivals";
      mrSteamId = "2767030";
      mrCompatDir = "${steamDir}/steamapps/compatdata/${mrSteamId}/pfx/drive_c/users/steamuser/AppData/Local/Marvel";
      mrGameDir = "${steamDir}/steamapps/common/MarvelRivals/MarvelGame/Marvel";

      # Wukong paths
      wkConfigDir = "${configDir}/wukong";
      wkSteamId = "2358720";
      wkCompatDir = "${steamDir}/steamapps/compatdata/${wkSteamId}/pfx/drive_c/users/steamuser/AppData/Local/b1";
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Check if Steam directory exists and is writable before proceeding
        if [ -d "${steamDir}" ] && [ -w "${steamDir}" ]; then
          # Marvel Rivals directories
          $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${mrGameDir}/Content/Paks/~mods/" 2>/dev/null || echo "Warning: Could not create Marvel Rivals mod directory"
          $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${mrCompatDir}/Saved/Config/Windows/" 2>/dev/null || echo "Warning: Could not create Marvel Rivals config directory"
          $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${mrCompatDir}/Saved/Saved/Config/" 2>/dev/null || echo "Warning: Could not create Marvel Rivals saved config directory"

          # Wukong directory
          $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${wkCompatDir}/Saved/Config/Windows/" 2>/dev/null || echo "Warning: Could not create Wukong config directory"

          # Symlink all mod files from the ~mods directory
          for modfile in $(find "${mrConfigDir}/~mods/" -type f 2>/dev/null); do
            filename=$(basename "$modfile")
            $DRY_RUN_CMD ln -sf $VERBOSE_ARG "$modfile" "${mrGameDir}/Content/Paks/~mods/$filename" 2>/dev/null || echo "Warning: Could not symlink mod file $filename"
          done
        else
          echo "Warning: Steam directory not found or not writable. Skipping game mod setup."
          echo "Steam directory: ${steamDir}"
          echo "To fix this, ensure Steam is installed and the directory has correct permissions."
        fi
      '';
  };
}
