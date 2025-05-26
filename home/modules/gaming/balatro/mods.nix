###############################################################################
# Balatro Mods Management Module - Pure Nix Store Version
# All mods are fetched through Nix store for reproducibility
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
  
  # Pure mod definitions with pinned versions
  pureMods = {
    # Repository mods - pinned to specific commits
    steamodded = {
      name = "smods";
      type = "repo";
      src = pkgs.fetchFromGitHub {
        owner = "Steamodded";
        repo = "smods";
        rev = "b163d0c0a04bdbc97559939952660cb3f185bb93";
        sha256 = "sha256-M04QnkFLF7B7SRu3b5ptkJPPqrmSJiFYD13x6WgaRLU=";
      };
    };
    talisman = {
      name = "Talisman";
      type = "repo";
      src = pkgs.fetchFromGitHub {
        owner = "SpectralPack";
        repo = "Talisman";
        rev = "f2911d467e660033c4d62c9f6aade2edb7ecc155";
        sha256 = "sha256-kva/QqiGtoYK8fvtaDjXBNS5od/7HEj8FsHXYGxFPXg=";
      };
    };
    cryptid = {
      name = "Cryptid";
      type = "repo";
      src = pkgs.fetchFromGitHub {
        owner = "SpectralPack";
        repo = "Cryptid";
        rev = "1da26300f239d77be0a9ffd24a75a9f7b6af724a";
        sha256 = "sha256-gwehpW9HenUxbO1s2USnXSkgkOGRetoIvWEfPj3CFNc=";
      };
    };
    multiplayer = {
      name = "BalatroMultiplayer";
      type = "repo";
      src = pkgs.fetchFromGitHub {
        owner = "Balatro-Multiplayer";
        repo = "BalatroMultiplayer";
        rev = "495f515806f0f07a8668a6fa3221ce4cc183356b";
        sha256 = "sha256-u77GooQ0kjOcE/8BE8A7xHIke7bZS8YNGkUD4tFDgKw=";
      };
    };
    cardsleeves = {
      name = "CardSleeves";
      type = "repo";
      src = pkgs.fetchFromGitHub {
        owner = "larswijn";
        repo = "CardSleeves";
        rev = "4250089ca52d4cb2d3cf6c2fd7d0d6ae66428650";
        sha256 = "sha256-V7punE+kdQb1+oQItd8yC3QymO35lgQnwZL9I8sa9Gs=";
      };
    };
    
    # Single file mods
    morespeeds = {
      name = "MoreSpeeds.lua";
      type = "file";
      src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/Steamodded/examples/refs/heads/master/Mods/MoreSpeeds.lua";
        sha256 = "1xj4mjr9firv24l115ldbxsyr0grpf1h4f22y8jrzvcw97d2xrlv";
      };
    };
    overlay = {
      name = "balatroverlay.lua";
      type = "file";
      src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/cantlookback/BalatrOverlay/refs/heads/main/balatroverlay.lua";
        sha256 = "1dx9sy84w1w77klfqmkmnalfvagpb1p9biazm6sakdz6d44470b7";
      };
    };
  };
  
  # Get enabled mods based on the list
  enabledMods = lib.filterAttrs (name: mod: lib.elem name cfg.enabledMods) pureMods;
  
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
  
  # Hash update script
  updateHashesScript = pkgs.writeShellScriptBin "update-balatro-hashes" ''
    set -euo pipefail
    
    echo "Updating Balatro mod hashes for pure mode..."
    
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
    
    echo "Getting latest commit hashes..."
    
    # Get latest commits
    STEAMODDED_REV=$(get_latest_commit "Steamodded" "smods")
    TALISMAN_REV=$(get_latest_commit "SpectralPack" "Talisman")
    CRYPTID_REV=$(get_latest_commit "SpectralPack" "Cryptid")
    MULTIPLAYER_REV=$(get_latest_commit "Balatro-Multiplayer" "BalatroMultiplayer")
    CARDSLEEVES_REV=$(get_latest_commit "larswijn" "CardSleeves")
    
    echo "Getting SHA256 hashes..."
    
    # Get hashes
    STEAMODDED_HASH=$(get_github_hash "Steamodded" "smods" "$STEAMODDED_REV")
    TALISMAN_HASH=$(get_github_hash "SpectralPack" "Talisman" "$TALISMAN_REV")
    CRYPTID_HASH=$(get_github_hash "SpectralPack" "Cryptid" "$CRYPTID_REV")
    MULTIPLAYER_HASH=$(get_github_hash "Balatro-Multiplayer" "BalatroMultiplayer" "$MULTIPLAYER_REV")
    CARDSLEEVES_HASH=$(get_github_hash "larswijn" "CardSleeves" "$CARDSLEEVES_REV")
    
    # Get file hashes
    MORESPEEDS_HASH=$(get_file_hash "https://raw.githubusercontent.com/Steamodded/examples/refs/heads/master/Mods/MoreSpeeds.lua")
    OVERLAY_HASH=$(get_file_hash "https://raw.githubusercontent.com/cantlookback/BalatrOverlay/refs/heads/main/balatroverlay.lua")
    
    echo ""
    echo "=== UPDATE mods.nix WITH THESE VALUES ==="
    echo ""
    echo "steamodded:"
    echo "  rev = \"$STEAMODDED_REV\";"
    echo "  sha256 = \"$STEAMODDED_HASH\";"
    echo ""
    echo "talisman:"
    echo "  rev = \"$TALISMAN_REV\";"
    echo "  sha256 = \"$TALISMAN_HASH\";"
    echo ""
    echo "cryptid:"
    echo "  rev = \"$CRYPTID_REV\";"
    echo "  sha256 = \"$CRYPTID_HASH\";"
    echo ""
    echo "multiplayer:"
    echo "  rev = \"$MULTIPLAYER_REV\";"
    echo "  sha256 = \"$MULTIPLAYER_HASH\";"
    echo ""
    echo "cardsleeves:"
    echo "  rev = \"$CARDSLEEVES_REV\";"
    echo "  sha256 = \"$CARDSLEEVES_HASH\";"
    echo ""
    echo "morespeeds:"
    echo "  sha256 = \"$MORESPEEDS_HASH\";"
    echo ""
    echo "overlay:"
    echo "  sha256 = \"$OVERLAY_HASH\";"
    echo ""
    echo "Done! Update mods.nix with these values and rebuild your system."
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
      type = lib.types.listOf (lib.types.enum (lib.attrNames pureMods));
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
      '') pureMods)}
      
      # Symlink enabled mods from Nix store
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: mod: ''
        if [ -e "${balatroModsPackage}/${mod.name}" ]; then
          ln -sf "${balatroModsPackage}/${mod.name}" "${balatroModsPath}/${mod.name}"
        fi
      '') enabledMods)}
      
      echo "Balatro mods (pure mode) installed: ${lib.concatStringsSep ", " cfg.enabledMods}"
    '';
    
    # Lovely Injector activation
    home.activation.lovelyInjector = lib.mkIf cfg.enableLovelyInjector (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Create game directory
        mkdir -p "${balatroGamePath}"
        
        # Symlink version.dll from Nix store
        ln -sf "${lovelyInjectorPackage}/version.dll" "${balatroGamePath}/version.dll"
        
        echo "Lovely Injector (pure mode) installed"
      ''
    );
    
    # Add packages to environment
    home.packages = with pkgs; [
      # The mod package itself
      balatroModsPackage
      # Hash update script
      updateHashesScript
      # Dependencies for the update script
      curl jq nix
    ] ++ lib.optional cfg.enableLovelyInjector lovelyInjectorPackage;
  };
}