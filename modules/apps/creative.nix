{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = {
    # Add creative applications
    home.packages = with pkgs; [
      pinta # Simple painting application
      gimp # Feature-rich image editor
    ];
  };
}
