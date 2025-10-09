{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
in {
  # Plugin configuration for Vesktop - opinionated defaults
  # All plugin configuration is handled directly in core.nix
  # This module exists for potential future plugin management features
  config = mkIf config.user.programs.vesktop.enable {
    # Future: Could add additional plugin management here if needed
  };
}
