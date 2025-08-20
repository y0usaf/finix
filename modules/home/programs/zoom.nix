{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.zoom;
in {
  options.home.programs.zoom = {
    enable = lib.mkEnableOption "Zoom video conferencing";

    extraFonts = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [
        pkgs.xorg.fontbitmaps
        pkgs.xorg.fontutil
        pkgs.xorg.fontxfree86type1
        pkgs.helvetica-neue-lt-std # Helvetica font commonly used by Zoom
      ];
      description = "Additional fonts to include for Zoom";
    };
  };

  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages =
        [
          pkgs.zoom-us
        ]
        ++ cfg.extraFonts;

      # Set environment variables for Zoom
      # This makes Zoom store its data in the XDG data directory
      sessionVariables = {
        SSB_HOME = "$XDG_DATA_HOME/zoom";
      };
    };
  };
}
