#═══════════════════════════ 🔧 ENVIRONMENT VARIABLES MODULE 🔧 ═══════════════════════════#
{
  config,
  lib,
  hostHome,
  ...
}: {
  # No need for module-defs import - using lib directly
  options.cfg.core.env = {
    enable = lib.mkEnableOption "home environment configuration (session vars/path)";
    # tokenDir now comes from cfg.shared.tokenDir - removed from core options
  };

  config.home = {
    # Conditionally apply session variables and path from core.env settings
    sessionVariables = lib.mkIf config.cfg.core.env.enable {
      LIBSEAT_BACKEND = "logind";
      # NH 4.0.3+ uses NH_FLAKE instead of FLAKE
      NH_FLAKE = hostHome.cfg.directories.flake.path;
      # Add other user session variables here
    };
    sessionPath = lib.mkIf config.cfg.core.env.enable [
      "$HOME/.local/bin"
      "/usr/lib/google-cloud-sdk/bin"
    ];
  };
}
