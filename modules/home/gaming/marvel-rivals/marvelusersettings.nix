# /home/y0usaf/nixos/modules/home/gaming/marvel-rivals/marvelusersettings.nix
# Manages the dynamic linking of the Marvel Rivals MarvelUserSetting.ini file
{
  config,
  pkgs,
  lib,
  ...
}: let
  # Read content from pkg directory
  marvelUserSettingsContent = builtins.readFile ../../../../pkg/gaming-config/marvel-rivals/MarvelUserSettings.ini;

  # Paths derived from original gaming.nix for the activation script
  # Note: Home path is implicitly handled by home-manager activation context
  mrSteamId = "2767030";
  mrSteamCompatDir = ".local/share/Steam/steamapps/compatdata/${mrSteamId}/pfx/drive_c/users/steamuser/AppData/Local/Marvel";
  mrProfileBaseDir = "${mrSteamCompatDir}/Saved/Saved/Config/"; # Base for finding profile dirs

  # Put MarvelUserSettings content into the store for the activation script
  marvelUserSettingsStorePath = pkgs.writeText "marvel-user-settings" marvelUserSettingsContent;
in {
  # Use activation script for the dynamically placed MarvelUserSettings.ini
  home.activation.linkMarvelUserSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Ensure base directories exist (target for GameUserSettings/Engine are implicitly handled by home.file)
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${config.home.homeDirectory}/${mrProfileBaseDir}"

    # Find and link MarvelUserSettings.ini into all profile directories
    # Using find -exec instead of a for loop for potentially better handling of names
    # The || echo ... ensures the command succeeds even if find returns nothing
    find "${config.home.homeDirectory}/${mrProfileBaseDir}" -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*' -exec bash -c '
      dir="$1"
      targetFile="$dir/MarvelUserSetting.ini" # Using the exact filename from original script
      echo "Linking MarvelUserSettings to $targetFile"
      # Use the store path of the content
      $DRY_RUN_CMD ln -sf $VERBOSE_ARG "${marvelUserSettingsStorePath}" "$targetFile"
    ' bash {} \; 2>/dev/null || echo "No existing profile directories found."

    # Create default profile directory and link if none exist
    # Check if the directory is empty or contains only dotfiles
    if ! ls -A "${config.home.homeDirectory}/${mrProfileBaseDir}" | grep -v '^\.' > /dev/null 2>&1; then
      echo "No profile directories found, creating default."
      defaultDir="${config.home.homeDirectory}/${mrProfileBaseDir}default/"
      targetFile="$defaultDir/MarvelUserSetting.ini" # Using the exact filename here too
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$defaultDir"
      # Use the store path of the content
      $DRY_RUN_CMD ln -sf $VERBOSE_ARG "${marvelUserSettingsStorePath}" "$targetFile"
    fi
  '';
}
