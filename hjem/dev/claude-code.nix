###############################################################################
# Claude Code IDE Configuration (Hjem Version)
# Installs and configures Claude Code AI assistant for development
# - Installs Claude Code via npm
# - Installs Brave Search integration
# - Configures PATH for global npm binaries
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.dev.claude-code;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.dev.claude-code = {
    enable = lib.mkEnableOption "Claude Code AI assistant";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packageCollector.packages = with pkgs; [
      claude-code
    ];
  };
}
