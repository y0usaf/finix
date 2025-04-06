###############################################################################
# Whisper Overlay Module (Fixed version)
# Provides speech-to-text via whisper-overlay
# - Server: realtime-stt-server (systemd user service)
# - Client: whisper-overlay application
###############################################################################
{ config, pkgs, lib, whisper-overlay, ... }:
let
  # Access the whisper-overlay flake passed directly as an argument
  whisper-overlay-flake = whisper-overlay;
  cfg = config.modules.programs.whisper-overlay;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.programs.whisper-overlay = {
    enable = lib.mkEnableOption "whisper-overlay speech-to-text";

    server = {
      enable = lib.mkEnableOption "realtime-stt-server systemd user service";
      autoStart = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to automatically start the realtime-stt-server service
          with the graphical session. If false, manage manually with
          `systemctl --user start/stop realtime-stt-server`.
        '';
      };
      # Add other server options here if needed in the future
    };

    client = {
      enable = lib.mkEnableOption "whisper-overlay client application";
      # Add client options here if needed (e.g., hotkey, style)
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    # Import the home manager module provided by the whisper-overlay flake
    imports = [whisper-overlay-flake.homeManagerModules.default];

    # Configure the server service if enabled
    services.realtime-stt-server = lib.mkIf cfg.server.enable {
      enable = true;
      autoStart = cfg.server.autoStart;
    };

    # Add the client package if enabled
    home.packages = lib.mkIf cfg.client.enable [
      # Get the package from the flake's provided packages
      whisper-overlay-flake.packages.${pkgs.system}.whisper-overlay
    ];

    # Reminder: Ensure CUDA support is enabled in nixpkgs config for performance
    # This is typically set in flake.nix or system configuration:
    # nixpkgs.config.cudaSupport = true;
  };
}