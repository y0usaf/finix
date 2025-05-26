###############################################################################
# Balatro Mods Installation Module - Pure npins Version
# All dependencies managed by npins (GitHub repos + file repos)
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.programs.gaming.balatro;

  # Import npins sources - everything managed by npins now!
  sources = import ./npins;

  # Define Steam paths for Balatro using XDG
  balatroModsPath = "${config.xdg.dataHome}/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods";
  balatroGamePath = "${config.xdg.dataHome}/Steam/steamapps/common/Balatro";

  # Available mods - completely uniform now!
  availableMods = {
    steamodded = {
      src = sources.steamodded;
      name = "smods";
    };
    talisman = {
      src = sources.talisman;
      name = "Talisman";
    };
    cryptid = {
      src = sources.cryptid;
      name = "Cryptid";
    };
    multiplayer = {
      src = sources.multiplayer;
      name = "BalatroMultiplayer";
    };
    cardsleeves = {
      src = sources.cardsleeves;
      name = "CardSleeves";
    };
    jokerdisplay = {
      src = sources.jokerdisplay;
      name = "JokerDisplay";
    };
    pokermon = {
      src = sources.pokermon;
      name = "Pokermon";
    };
    morespeeds = {
      src = "${sources.steamodded-examples}/Mods/MoreSpeeds.lua";
      name = "MoreSpeeds.lua";
    };
    overlay = {
      src = "${sources.balatroverlay}/balatroverlay.lua";
      name = "balatroverlay.lua";
    };
  };

  # Get enabled mods based on the list
  enabledMods = lib.filterAttrs (name: mod: lib.elem name cfg.enabledMods) availableMods;

  # Create a combined derivation with all enabled mods
  balatroModsPackage = pkgs.runCommand "balatro-mods" {} ''
    mkdir -p $out

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: mod: ''
        cp -r ${mod.src} $out/${mod.name}
        chmod -R +w $out/${mod.name}
      '')
      enabledMods)}
  '';

  # Lovely Injector using fetchZip (no manual unzip needed!)
  lovelyInjectorPackage = pkgs.fetchZip {
    url = "https://github.com/ethangreen-dev/lovely-injector/releases/download/v0.7.1/lovely-x86_64-pc-windows-msvc.zip";
    sha256 = "04zbhsh8qsn0mqw302p6wamrfw8snkrbl6x6r1pbqxfiiclgv0z7";
    stripRoot = false;
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
      type = lib.types.listOf (lib.types.enum (lib.attrNames availableMods));
      default = [];
      example = ["steamodded" "talisman" "cryptid" "multiplayer" "cardsleeves" "jokerdisplay" "morespeeds" "overlay"];
      description = ''
        List of mod names to enable. Available mods:
        - steamodded: Steamodded/smods (core modding framework)
        - talisman: SpectralPack/Talisman
        - cryptid: SpectralPack/Cryptid
        - multiplayer: Balatro-Multiplayer/BalatroMultiplayer
        - cardsleeves: larswijn/CardSleeves
        - jokerdisplay: nh6574/JokerDisplay (shows joker calculations)
        - pokermon: InertSteak/Pokermon (Pokemon-themed jokers)
        - morespeeds: MoreSpeeds.lua (from Steamodded/examples)
        - overlay: BalatrOverlay.lua (from cantlookback/BalatrOverlay)
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Symlink enabled mods from Nix store
    home.activation.balatroMods = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create mods directory
      mkdir -p "${balatroModsPath}"

      # Clean existing mods - remove ALL existing symlinks and directories first
      find "${balatroModsPath}" -mindepth 1 -maxdepth 1 -exec rm -rf {} \; 2>/dev/null || true

      # Symlink enabled mods from Nix store
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: mod: ''
          if [ -e "${balatroModsPackage}/${mod.name}" ]; then
            ln -sf "${balatroModsPackage}/${mod.name}" "${balatroModsPath}/${mod.name}"
          fi
        '')
        enabledMods)}

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
    home.packages = with pkgs;
      [
        # The mod package itself
        balatroModsPackage
      ]
      ++ lib.optional cfg.enableLovelyInjector lovelyInjectorPackage;
  };
}
