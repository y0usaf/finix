{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.user.gaming.steam;
in {
  options.user.gaming.steam = {
    enable = lib.mkEnableOption "Steam with enhanced configuration";

    shaderThreads = lib.mkOption {
      type = lib.types.int;
      default = config.nix.settings.max-jobs;
      description = ''
        Number of concurrent threads for shader compilation in Steam.
        Defaults to nix.settings.max-jobs for optimal performance.
      '';
    };

    hardware.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable hardware support for Steam Controllers, VR devices, etc.";
    };

    remotePlay.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Steam Remote Play with automatic firewall configuration";
    };

    dedicatedServer.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Steam dedicated server support with firewall rules";
    };

    protonGE.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Proton GE support via protonup-rs";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable Steam with requested features
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = cfg.remotePlay.enable;
      dedicatedServer.openFirewall = cfg.dedicatedServer.enable;
    };

    # Enable hardware support for Steam peripherals
    hardware.steam-hardware.enable = cfg.hardware.enable;

    # Configure shader compilation threads
    usr.files.".config/steam/steam_dev.cfg" = {
      text = ''
        unShaderBackgroundProcessingThreads ${toString cfg.shaderThreads}
      '';
      clobber = true;
    };

    # Install Steam-related packages
    environment.systemPackages =
      [
        pkgs.gamescope
        pkgs.gamemode
        pkgs.protontricks
      ]
      ++ lib.optionals cfg.protonGE.enable [
        pkgs.protonup-rs
      ];
  };
}
