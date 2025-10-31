{
  config,
  pkgs,
  lib,
  ...
}: let
  sources = import ./npins;

  clairobscurfix = pkgs.fetchzip {
    url = "https://codeberg.org/Lyall/ClairObscurFix/releases/download/${sources.ClairObscurFix.version}/ClairObscurFix_${sources.ClairObscurFix.version}.zip";
    sha256 = "160xv8gb95rn2kpcwv65j3q8fsi1wiayqchgn4gnkrh6g909qzrb";
    stripRoot = false;
  };
in {
  options.user.gaming.clair-obscur.clairobscurfix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ClairObscurFix plugin installation";
    };
  };

  config = lib.mkIf config.user.gaming.clair-obscur.clairobscurfix.enable {
    usr.files = {
      ".local/share/Steam/steamapps/common/Expedition 33/Sandfall/Binaries/Win64/ClairObscurFix.asi" = {
        clobber = true;
        source = "${clairobscurfix}/ClairObscurFix.asi";
      };

      ".local/share/Steam/steamapps/common/Expedition 33/Sandfall/Binaries/Win64/dsound.dll" = {
        clobber = true;
        source = "${clairobscurfix}/dsound.dll";
      };

      ".local/share/Steam/steamapps/common/Expedition 33/Sandfall/Binaries/Win64/ClairObscurFix.ini" = {
        clobber = true;
        generator = lib.generators.toINI {};
        value = {
          "Developer Console" = {
            Enabled = true;
          };
          "Skip Intro Logos" = {
            Enabled = true;
          };
          "Uncap Cutscene FPS" = {
            Enabled = true;
            AllowFrameGen = false;
          };
          "Adjust Resolution Checks" = {
            Enabled = true;
          };
          "Maximum Timer Resolution" = {
            Enabled = true;
          };
          "Cutscenes" = {
            DisableLetterboxing = true;
            DisablePillarboxing = true;
          };
          "Fix Movies" = {
            Enabled = true;
          };
          "Disable Subtitle Blur" = {
            Enabled = false;
          };
          "Sharpening" = {
            Strength = "0";
          };
        };
      };
    };
  };
}
