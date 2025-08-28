{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
in {
  # Audio/video configuration for Vesktop - opinionated defaults
  # Audio/video settings are typically handled by Discord's runtime settings
  # This module exists for potential future audio/video configuration
  config = mkIf config.home.programs.vesktop.enable {
    # Future: Could add audio/video configuration here if needed
  };
}
