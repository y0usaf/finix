{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) concatStringsSep mkEnableOption mkIf;

  enableFeatures = [
    "WaylandWindowDecorations"
    "WaylandLinuxDrmSyncobj"
  ];
  disableFeatures = [
    "WebRtcAllowInputVolumeAdjustment"
    "ChromeWideEchoCancellation"
  ];
  inherit (config) user;
  userName = user.name;
  stableCfg = user.programs.discord.stable;
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
  };

  config = mkIf stableCfg.enable {
    environment.systemPackages = [
      ((
          if stableCfg.pinLegacy
          then legacyDiscord
          else pkgs.discord
        ).override {
          commandLineArgs = "--enable-features=${concatStringsSep "," enableFeatures} --disable-features=${concatStringsSep "," disableFeatures}";
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
          SKIP_MODULE_UPDATE = true;
          MINIMIZE_TO_TRAY = false;
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
              @import url("file:///home/${userName}/.config/Vencord/themes/wallust-colors.css");
            '';
          };
        };
      };
    };
  };
}
