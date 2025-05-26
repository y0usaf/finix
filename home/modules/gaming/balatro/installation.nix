###############################################################################
# Balatro Mods Installation Module - Pure Nix Store Version
# All mods are fetched through Nix store for reproducibility
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.programs.gaming.balatro;
  
  # Import mod definitions
  modDefinitions = import ./mods.nix {};
  
  # Define the Steam paths for Balatro using XDG
  balatroModsPath = "${config.xdg.dataHome}/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods";
  balatroGamePath = "${config.xdg.dataHome}/Steam/steamapps/common/Balatro";
  
  # Convert mod definitions to Nix packages
  mods = lib.mapAttrs (name: modDef: 
    if modDef.type == "repo" then {
      inherit (modDef) name type;
      src = pkgs.fetchFromGitHub {
        owner = modDef.owner;
        repo = modDef.repo;
        rev = modDef.rev;
        sha256 = modDef.sha256;
      };
    } else if modDef.type == "file" then {
      inherit (modDef) name type;
      src = pkgs.fetchurl {
        url = modDef.url;
        sha256 = modDef.sha256;
      };
    } else modDef
  ) modDefinitions;
  
  # Get enabled mods based on the list
  enabledMods = lib.filterAttrs (name: mod: lib.elem name cfg.enabledMods) mods;
  
  # Create a combined derivation with all enabled mods
  balatroModsPackage = pkgs.runCommand "balatro-mods" {} ''
    mkdir -p $out
    
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: mod:
      if mod.type == "repo" then ''
        cp -r ${mod.src} $out/${mod.name}
        chmod -R +w $out/${mod.name}
      '' else if mod.type == "file" then ''
        cp ${mod.src} $out/${mod.name}
      '' else ""
    ) enabledMods)}
  '';
  
  # Programmatic hash update script
  updateHashesScript = pkgs.writeShellScriptBin "update-balatro-hashes" ''
    set -euo pipefail
    
    MODS_FILE="$HOME/nixos/home/modules/gaming/balatro/mods.nix"
    
    if [ ! -f "$MODS_FILE" ]; then
      echo "Error: $MODS_FILE not found!"
      exit 1
    fi
    
    echo "Updating Balatro mod hashes..."
    
    # Function to get latest commit hash
    get_latest_commit() {
        local owner="$1"
        local repo="$2"
        local branch="''${3:-main}"
        ${pkgs.curl}/bin/curl -s "https://api.github.com/repos/$owner/$repo/commits/$branch" | ${pkgs.jq}/bin/jq -r '.sha'
    }
    
    # Function to get GitHub repo hash
    get_github_hash() {
        local owner="$1"
        local repo="$2"
        local rev="$3"
        ${pkgs.nix}/bin/nix-shell -p nix-prefetch-github --run "nix-prefetch-github $owner $repo --rev $rev" | ${pkgs.jq}/bin/jq -r '.hash'
    }
    
    # Function to get file hash
    get_file_hash() {
        local url="$1"
        ${pkgs.nix}/bin/nix-prefetch-url "$url"
    }
    
    # Function to update a repo mod
    update_repo_mod() {
        local mod_name="$1"
        local owner="$2"
        local repo="$3"
        
        echo "Updating $mod_name..."
        local new_rev=$(get_latest_commit "$owner" "$repo")
        local new_hash=$(get_github_hash "$owner" "$repo" "$new_rev")
        
        # Update rev
        ${pkgs.gnused}/bin/sed -i "/$mod_name = {/,/};/{
          s/rev = \"[^\"]*\";/rev = \"$new_rev\";/
        }" "$MODS_FILE"
        
        # Update sha256
        ${pkgs.gnused}/bin/sed -i "/$mod_name = {/,/};/{
          s/sha256 = \"[^\"]*\";/sha256 = \"$new_hash\";/
        }" "$MODS_FILE"
        
        echo "  $mod_name: $new_rev"
    }
    
    # Function to update a file mod
    update_file_mod() {
        local mod_name="$1"
        local url="$2"
        
        echo "Updating $mod_name..."
        local new_hash=$(get_file_hash "$url")
        
        # Update sha256
        ${pkgs.gnused}/bin/sed -i "/$mod_name = {/,/};/{
          s/sha256 = \"[^\"]*\";/sha256 = \"$new_hash\";/
        }" "$MODS_FILE"
        
        echo "  $mod_name: $new_hash"
    }
    
    # Update all repository mods
    update_repo_mod "steamodded" "Steamodded" "smods"
    update_repo_mod "talisman" "SpectralPack" "Talisman"
    update_repo_mod "cryptid" "SpectralPack" "Cryptid"
    update_repo_mod "multiplayer" "Balatro-Multiplayer" "BalatroMultiplayer"
    update_repo_mod "cardsleeves" "larswijn" "CardSleeves"
    update_repo_mod "jokerdisplay" "nh6574" "JokerDisplay"
    update_repo_mod "pokermon" "InertSteak" "Pokermon"
    
    # Update file mods
    update_file_mod "morespeeds" "https://raw.githubusercontent.com/Steamodded/examples/refs/heads/master/Mods/MoreSpeeds.lua"
    update_file_mod "overlay" "https://raw.githubusercontent.com/cantlookback/BalatrOverlay/refs/heads/main/balatroverlay.lua"
    
    echo ""
    echo "✅ All mod hashes updated successfully!"
    echo "📁 Updated file: $MODS_FILE"
    echo "🔄 Run 'nh os switch --dry' to preview changes, then 'nh os switch' to apply"
  '';
  
  # Lovely Injector pure version
  lovelyInjectorPackage = pkgs.stdenv.mkDerivation rec {
    pname = "lovely-injector";
    version = "0.7.1"; # Update this when needed
    
    src = pkgs.fetchurl {
      url = "https://github.com/ethangreen-dev/lovely-injector/releases/download/v${version}/lovely-x86_64-pc-windows-msvc.zip";
      sha256 = "0pgcanbqdmps41jagzz5kkd15dq25xkpkgdvsvvcs3a3bisqsgdj";
    };
    
    nativeBuildInputs = [ pkgs.unzip ];
    
    unpackPhase = ''
      unzip $src
    '';
    
    installPhase = ''
      mkdir -p $out
      cp version.dll $out/
    '';
  };

in {
  options.cfg.programs.gaming.balatro = {
    enable = lib.mkEnableOption "Balatro mod management";
    
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
      type = lib.types.listOf (lib.types.enum (lib.attrNames mods));
      default = [];
      example = [ "steamodded" "talisman" "cryptid" "multiplayer" "cardsleeves" "jokerdisplay" "morespeeds" "overlay" ];
      description = ''
        List of mod names to enable. Available mods:
        - steamodded: Steamodded/smods (core modding framework)
        - talisman: SpectralPack/Talisman
        - cryptid: SpectralPack/Cryptid  
        - multiplayer: Balatro-Multiplayer/BalatroMultiplayer
        - cardsleeves: larswijn/CardSleeves
        - jokerdisplay: nh6574/JokerDisplay (shows joker calculations)
        - pokermon: InertSteak/Pokermon (Pokemon-themed jokers)
        - morespeeds: MoreSpeeds.lua (single file)
        - overlay: BalatrOverlay.lua (single file)
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Pure mode: symlink from Nix store
    home.activation.balatroMods = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create mods directory
      mkdir -p "${balatroModsPath}"
      
      # Clean existing mods (remove broken symlinks)
      find "${balatroModsPath}" -type l ! -exec test -e {} \; -delete 2>/dev/null || true
      
      # Remove old mod directories/files that aren't symlinks
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: mod: ''
        if [ -e "${balatroModsPath}/${mod.name}" ] && [ ! -L "${balatroModsPath}/${mod.name}" ]; then
          rm -rf "${balatroModsPath}/${mod.name}"
        fi
      '') mods)}
      
      # Symlink enabled mods from Nix store
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: mod: ''
        if [ -e "${balatroModsPackage}/${mod.name}" ]; then
          ln -sf "${balatroModsPackage}/${mod.name}" "${balatroModsPath}/${mod.name}"
        fi
      '') enabledMods)}
      
      echo "Balatro mods installed: ${lib.concatStringsSep ", " cfg.enabledMods}"
    '';
    
    # Lovely Injector activation
    home.activation.lovelyInjector = lib.mkIf cfg.enableLovelyInjector (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Create game directory
        mkdir -p "${balatroGamePath}"
        
        # Symlink version.dll from Nix store
        ln -sf "${lovelyInjectorPackage}/version.dll" "${balatroGamePath}/version.dll"
        
        echo "Lovely Injector installed"
      ''
    );
    
    # Add packages to environment
    home.packages = with pkgs; [
      # The mod package itself
      balatroModsPackage
      # Hash update script
      updateHashesScript
      # Dependencies for the update script
      curl jq nix gnused
    ] ++ lib.optional cfg.enableLovelyInjector lovelyInjectorPackage;
  };
}