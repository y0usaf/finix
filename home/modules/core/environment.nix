#═══════════════════════════ 🔧 ENVIRONMENT VARIABLES MODULE 🔧 ═══════════════════════════#
{
  config,
  lib,
  pkgs,
  inputs,
  hostSystem,
  hostHome,
  ...
}: {
  # No need for module-defs import - using lib directly
  options.cfg.core.env = {
    enable = lib.mkEnableOption "home environment configuration (session vars/path)";
    tokenDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/Tokens";
      description = "Directory containing token files to be loaded by zsh as env variables";
    };
  };

  config.home = {
    # Conditionally apply session variables and path from core.env settings
    sessionVariables = lib.mkIf config.cfg.core.env.enable {
      LIBSEAT_BACKEND = "logind";
      # Add other user session variables here
    };
    sessionPath = lib.mkIf config.cfg.core.env.enable [
      "$HOME/.local/bin"
      "/usr/lib/google-cloud-sdk/bin"
    ];
  };
}