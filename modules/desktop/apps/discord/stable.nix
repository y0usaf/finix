{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) concatStringsSep optionals mkEnableOption mkOption mkIf types;

  enableFeatures = [
    # WaylandLinuxDrmSyncobj removed - causes format negotiation failures with niri screenshare
    # See: pw.link: negotiating -> error no more input formats (-22)
  ];
  disableFeatures = [
    "WebRtcAllowInputVolumeAdjustment"
    "ChromeWideEchoCancellation"
  ];
  inherit (config) user;
  userName = user.name;
  stableCfg = user.programs.discord.stable;

  # Discord pinned to the last release before the distro-format repackaging,
  # built from the legacy nixpkgs snapshot's package files against *current*
  # pkgs. This avoids instantiating a full second nixpkgs (~1s eval + ~300MB
  # RAM per host) just for one package.
  legacyDir = "${flakeInputs.nixpkgs-discord-legacy}/pkgs/applications/networking/instant-messengers/discord";
  legacySource = (lib.importJSON "${legacyDir}/sources.json")."linux-stable";
  legacyDiscord = pkgs.callPackage "${legacyDir}/linux.nix" {
    pname = "discord";
    inherit (legacySource) version;
    src = pkgs.fetchurl {inherit (legacySource) url hash;};
    branch = "stable";
    binaryName = "Discord";
    desktopName = "Discord";
    self = legacyDiscord;
    meta = {
      description = "All-in-one cross-platform voice and text chat for gamers";
      mainProgram = "Discord";
    };
  };
in {
  options.user.programs.discord.stable = {
    enable = mkEnableOption "Discord stable";
    pinLegacy = mkEnableOption "pin Discord to the legacy 0.0.125 release";
    package = mkOption {
      type = types.package;
      default =
        if stableCfg.pinLegacy
        then legacyDiscord
        else pkgs.discord;
      defaultText = lib.literalExpression "pkgs.discord";
      description = "Discord package to customize and install";
    };
    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra command line arguments to pass to Discord";
    };
    minimizeToTray =
      mkEnableOption "Minimize to tray on close"
      // {default = false;};
    smoothScroll =
      mkEnableOption "Smooth scrolling"
      // {default = true;};
  };

  config = mkIf stableCfg.enable {
    environment.systemPackages = [
      (stableCfg.package.override {
        commandLineArgs = concatStringsSep " " ((optionals (enableFeatures != []) [
            "--enable-features=${concatStringsSep "," enableFeatures}"
          ]
          ++ optionals (disableFeatures != []) [
            "--disable-features=${concatStringsSep "," disableFeatures}"
          ]
          ++ optionals (!stableCfg.smoothScroll) [
            "--disable-smooth-scrolling"
          ])
        ++ stableCfg.extraArgs);
        withOpenASAR = true;
        disableUpdates = false;
        withTTS = false;
        enableAutoscroll = true;
      })
    ];

    manzil.users."${userName}".files = {
      ".config/discord/settings.json" = {
        generator = lib.generators.toJSON {};
        value = {
          SKIP_HOST_UPDATE = true;
          UPDATE_ENDPOINT = "https://inject.shelter.uwu.network/vencord";
          NEW_UPDATE_ENDPOINT = "https://inject.shelter.uwu.network/vencord/";
          MINIMIZE_TO_TRAY = stableCfg.minimizeToTray;
          OPEN_ON_STARTUP = false;
          DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
          enableHardwareAcceleration = true;
          openH264Enabled = true;
          openasar = {
            setup = true;
            cmdPreset = "balanced";
            quickstart = false;
            css = ''
              @import url("file:///home/${userName}/.config/Vencord/themes/disblock.css");
              @import url("file:///home/${userName}/.config/Vencord/themes/visual-refresh-hide-2.css");
              @import url("file:///home/${userName}/.config/Vencord/themes/visual-refresh-hide-3.css");
              @import url("file:///home/${userName}/.config/Vencord/themes/visual-refresh-hide-4.css");
              @import url("file:///home/${userName}/.config/Vencord/themes/visual-refresh-hide-5.css");
              @import url("file:///home/${userName}/.config/Vencord/themes/system-font.css");
            '';
          };
        };
      };
    };
  };
}
