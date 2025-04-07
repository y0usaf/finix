###############################################################################
# Whisper Overlay Module (Consolidated)
# Provides speech-to-text via whisper-overlay
# - Server: realtime-stt-server (systemd user service)
# - Client: whisper-overlay application
###############################################################################
{
  config,
  pkgs,
  lib,
  whisper-overlay ? null,
  ...
}: let
  # Access the whisper-overlay flake input from regular arguments or try specialArgs as fallback
  whisper-overlay-flake =
    if whisper-overlay != null
    then whisper-overlay
    else
      (
        if builtins.hasAttr "specialArgs" config && builtins.hasAttr "whisper-overlay" config.specialArgs
        then config.specialArgs.whisper-overlay
        else throw "whisper-overlay flake input not provided"
      );
  cfg = config.cfg.programs.whisper-overlay;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.programs.whisper-overlay = {
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
    # Add packages based on enabled components
    home.packages = lib.mkMerge [
      # Add the client package if client is enabled
      (lib.mkIf cfg.client.enable [
        whisper-overlay-flake.packages.${pkgs.system}.whisper-overlay
      ])

      # Add the server package if server is enabled
      (lib.mkIf cfg.server.enable [
        whisper-overlay-flake.packages.${pkgs.system}.realtime-stt-server
      ])
    ];

    # Configure the systemd user service for the server if enabled
    systemd.user.services = lib.mkIf cfg.server.enable {
      realtime-stt-server = {
        Unit = {
          Description = "Real-time speech-to-text server for whisper-overlay";
          After = ["graphical-session-pre.target"];
          PartOf = ["graphical-session.target"];
        };

        Service = {
          ExecStart = "${whisper-overlay-flake.packages.${pkgs.system}.realtime-stt-server}/bin/realtime-stt-server";
          Restart = "on-failure";
        };

        Install = {
          WantedBy = lib.mkIf cfg.server.autoStart ["graphical-session.target"];
        };
      };
    };

    # Reminder: Ensure CUDA support is enabled in nixpkgs config for performance
    # This is typically set in flake.nix or system configuration:
    # nixpkgs.config.cudaSupport = true;
  };
}
