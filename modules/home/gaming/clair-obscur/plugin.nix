{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.gaming.clair-obscur.plugin;
  sources = import ./npins;

  clairobscurfix = pkgs.fetchzip {
    url = "https://codeberg.org/Lyall/ClairObscurFix/releases/download/${sources.ClairObscurFix.version}/ClairObscurFix_${sources.ClairObscurFix.version}.zip";
    sha256 = sources.ClairObscurFix.hash;
    stripRoot = false;
  };
in {
  options.home.gaming.clair-obscur.plugin = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ClairObscurFix plugin installation";
    };
  };

  config = lib.mkIf cfg.enable {
    usr.files = {
      # Install the ASI plugin
      ".local/share/Steam/steamapps/common/Expedition 33/ClairObscurFix.asi" = {
        clobber = true;
        source = "${clairobscurfix}/ClairObscurFix.asi";
      };

      # Install the configuration file
      ".local/share/Steam/steamapps/common/Expedition 33/ClairObscurFix.ini" = {
        clobber = true;
        generator = lib.generators.toINI {};
        value = {
          Settings = {
            # Remove 30fps cap in cutscenes
            RemoveCutsceneFPSCap = true;
            # Disable game sharpening
            DisableSharpening = true;
            # Skip intro logos
            SkipIntroLogos = true;
            # Enable developer console
            EnableConsole = true;
            # Ultrawide/aspect ratio fixes
            UltrawideSupport = true;
          };
        };
      };
    };
  };
}
