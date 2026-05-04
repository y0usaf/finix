{
  config,
  lib,
  ...
}: let
  inherit (config) user;
  mods = config.user.gaming.mods.expedition33;
  steamPath = lib.removePrefix "${user.homeDirectory}/" user.paths.steam.path;
in {
  config = lib.mkIf user.gaming.expedition33.enable {
    manzil.users."${config.user.name}".files = {
      "${steamPath}/steamapps/common/Expedition 33/Sandfall/Binaries/Win64/ClairObscurFix.asi" = {
        source = "${mods.ClairObscurFix.src}/ClairObscurFix.asi";
      };

      "${steamPath}/steamapps/common/Expedition 33/Sandfall/Binaries/Win64/dsound.dll" = {
        source = "${mods.ClairObscurFix.src}/dsound.dll";
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
