{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config) user;
  clairObscurVersion = (import ./npins).ClairObscurFix.version;
  steamPath = lib.removePrefix "${user.homeDirectory}/" user.paths.steam.path;

  clairobscurfix = pkgs.fetchzip {
    url = "https://codeberg.org/Lyall/ClairObscurFix/releases/download/${clairObscurVersion}/ClairObscurFix_${clairObscurVersion}.zip";
    sha256 = "160xv8gb95rn2kpcwv65j3q8fsi1wiayqchgn4gnkrh6g909qzrb";
    stripRoot = false;
  };
in {
  config = lib.mkIf user.gaming.expedition33.enable {
    usr.files = {
      "${steamPath}/steamapps/common/Expedition 33/Sandfall/Binaries/Win64/ClairObscurFix.asi" = {
        clobber = true;
        source = "${clairobscurfix}/ClairObscurFix.asi";
      };

      "${steamPath}/steamapps/common/Expedition 33/Sandfall/Binaries/Win64/dsound.dll" = {
        clobber = true;
        source = "${clairobscurfix}/dsound.dll";
      };

      "${steamPath}/steamapps/common/Expedition 33/Sandfall/Binaries/Win64/ClairObscurFix.ini" = {
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
