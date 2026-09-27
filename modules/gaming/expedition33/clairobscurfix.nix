{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) user;
  version = "0.0.13";
  clairObscurFix = pkgs.fetchzip {
    url = "https://codeberg.org/Lyall/ClairObscurFix/releases/download/${version}/ClairObscurFix_${version}.zip";
    sha256 = "160xv8gb95rn2kpcwv65j3q8fsi1wiayqchgn4gnkrh6g909qzrb";
    stripRoot = false;
  };
  steamPath = lib.removePrefix "${user.homeDirectory}/" user.paths.steam;
in {
  config = lib.mkIf user.gaming.expedition33.enable {
    manzil.users."${config.user.name}".files = {
      "${steamPath}/steamapps/common/Expedition 33/Sandfall/Binaries/Win64/ClairObscurFix.asi" = {
        source = "${clairObscurFix}/ClairObscurFix.asi";
      };

      "${steamPath}/steamapps/common/Expedition 33/Sandfall/Binaries/Win64/dsound.dll" = {
        source = "${clairObscurFix}/dsound.dll";
      };

      "${steamPath}/steamapps/common/Expedition 33/Sandfall/Binaries/Win64/ClairObscurFix.ini" = {
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
