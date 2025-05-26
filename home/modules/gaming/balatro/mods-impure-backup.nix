###############################################################################
# Balatro Mods Management Module - Simplified
# Just specify a list of mod names to enable
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.programs.gaming.balatro;
  
  # Define the Steam paths for Balatro using XDG
  balatroModsPath = "${config.xdg.dataHome}/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods";
  balatroGamePath = "${config.xdg.dataHome}/Steam/steamapps/common/Balatro";
  
  # All available mods - users just reference by name
  allMods = {
    # Repository mods
    steamodded = {
      name = "smods";
      type = "repo";
      url = "https://github.com/Steamodded/smods";
    };
    talisman = {
      name = "Talisman";
      type = "repo";
      url = "https://github.com/SpectralPack/Talisman";
    };
    cryptid = {
      name = "Cryptid";
      type = "repo";
      url = "https://github.com/SpectralPack/Cryptid";
    };
    multiplayer = {
      name = "BalatroMultiplayer";
      type = "repo";
      url = "https://github.com/Balatro-Multiplayer/BalatroMultiplayer";
    };
    cardsleeves = {
      name = "CardSleeves";
      type = "repo";
      url = "https://github.com/larswijn/CardSleeves";
    };
    
    # Single file mods
    morespeeds = {
      name = "MoreSpeeds.lua";
      type = "file";
      url = "https://raw.githubusercontent.com/Steamodded/examples/refs/heads/master/Mods/MoreSpeeds.lua";
    };
    overlay = {
      name = "balatroverlay.lua";
      type = "file";
      url = "https://raw.githubusercontent.com/cantlookback/BalatrOverlay/refs/heads/main/balatroverlay.lua";
    };
  };
  
  # Get enabled mods based on the list
  enabledMods = lib.filterAttrs (name: mod: lib.elem name cfg.enabledMods) allMods;
  
  # Lovely Injector installation service script
  lovelyInjectorScript = pkgs.writeShellScript "install-lovely-injector" ''
    set -euo pipefail
    
    echo "Installing Lovely Injector..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    cd "$TEMP_DIR"
    
    # Get latest release info from GitHub API
    echo "Fetching latest Lovely Injector release..."
    RELEASE_URL=$(${pkgs.curl}/bin/curl -s https://api.github.com/repos/ethangreen-dev/lovely-injector/releases/latest | \
      ${pkgs.jq}/bin/jq -r '.assets[] | select(.name == "lovely-x86_64-pc-windows-msvc.zip") | .browser_download_url')
    
    if [ "$RELEASE_URL" = "null" ] || [ -z "$RELEASE_URL" ]; then
      echo "Error: Could not find lovely-x86_64-pc-windows-msvc.zip in latest release" >&2
      exit 1
    fi
    
    # Download the release
    echo "Downloading: $RELEASE_URL"
    ${pkgs.curl}/bin/curl -L -o lovely-injector.zip "$RELEASE_URL"
    
    # Extract version.dll
    echo "Extracting version.dll..."
    ${pkgs.unzip}/bin/unzip -j lovely-injector.zip version.dll
    
    # Ensure game directory exists
    mkdir -p "${balatroGamePath}"
    
    # Copy version.dll to game directory
    echo "Installing version.dll to ${balatroGamePath}"
    cp version.dll "${balatroGamePath}/"
    
    echo "Lovely Injector installed successfully!"
  '';
  
  # Mod management service script
  modManagementScript = pkgs.writeShellScript "manage-balatro-mods" ''
    set -euo pipefail
    
    mkdir -p "${balatroModsPath}"
    echo "Managing Balatro mods..."
    echo "Enabled mods: ${lib.concatStringsSep ", " cfg.enabledMods}"
    
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: mod:
      if mod.type == "repo" then ''
        echo "Managing mod repository: ${mod.name}"
        if [ -d "${balatroModsPath}/${mod.name}" ]; then
          echo "Updating: ${mod.name}"
          cd "${balatroModsPath}/${mod.name}"
          ${pkgs.git}/bin/git pull origin main 2>/dev/null || ${pkgs.git}/bin/git pull origin master 2>/dev/null || echo "Update failed for ${mod.name}"
        else
          echo "Cloning: ${mod.name}"
          cd "${balatroModsPath}"
          ${pkgs.git}/bin/git clone "${mod.url}" "${mod.name}" || echo "Clone failed for ${mod.name}"
        fi
      '' else if mod.type == "file" then ''
        echo "Downloading mod file: ${mod.name}"
        ${pkgs.curl}/bin/curl -L -o "${balatroModsPath}/${mod.name}" "${mod.url}" || echo "Download failed for ${mod.name}"
      '' else ''echo "Unknown mod type: ${mod.type}"''
    ) enabledMods)}
    
    # Clean up disabled mods
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: mod:
      if !(lib.elem name cfg.enabledMods) then
        if mod.type == "repo" then ''
          if [ -d "${balatroModsPath}/${mod.name}" ]; then
            echo "Removing disabled mod: ${mod.name}"
            rm -rf "${balatroModsPath}/${mod.name}"
          fi
        '' else if mod.type == "file" then ''
          if [ -f "${balatroModsPath}/${mod.name}" ]; then
            echo "Removing disabled file: ${mod.name}"
            rm -f "${balatroModsPath}/${mod.name}"
          fi
        '' else ""
      else ""
    ) allMods)}
    
    echo "Balatro mod management completed"
  '';

in {
  options.cfg.programs.gaming.balatro = {
    enable = lib.mkEnableOption "Balatro mod management";
    
    pureMode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use pure Nix store mode for mod management.
        When true, all mods are fetched through Nix store for reproducibility.
        When false, uses impure runtime downloading for easier updates.
      '';
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
      type = lib.types.listOf (lib.types.enum (lib.attrNames allMods));
      default = [];
      example = [ "steamodded" "talisman" "cryptid" "multiplayer" "cardsleeves" "morespeeds" "overlay" ];
      description = ''
        List of mod names to enable. Available mods:
        - steamodded: Steamodded/smods (core modding framework)
        - talisman: SpectralPack/Talisman
        - cryptid: SpectralPack/Cryptid  
        - multiplayer: Balatro-Multiplayer/BalatroMultiplayer
        - cardsleeves: larswijn/CardSleeves
        - morespeeds: MoreSpeeds.lua (single file)
        - overlay: BalatrOverlay.lua (single file)
      '';
    };
    
    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically update mods on system activation";
    };
  };

  config = lib.mkIf (cfg.enable && !cfg.pureMode) {
    # Provide scripts as packages
    home.packages = with pkgs; [
      git curl jq unzip
      
      # Lovely Injector installation script
      (lib.mkIf cfg.enableLovelyInjector (
        writeShellScriptBin "install-lovely-injector" ''
          ${lovelyInjectorScript}
        ''
      ))
      
      # Mod management script
      (writeShellScriptBin "update-balatro-mods" ''
        ${modManagementScript}
      '')
    ];
  };
}