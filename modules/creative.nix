{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = lib.mkIf (builtins.elem "creative" profile.features) {
    # Add creative applications
    home.packages = with pkgs; [
      pinta     # Simple painting application
      gimp      # Feature-rich image editor
    ];
  };
} 