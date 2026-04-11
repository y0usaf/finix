{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
in {
  config = mkIf config.user.gaming.core.enable (let
    steamPath = lib.removePrefix "${config.user.homeDirectory}/" config.user.paths.steam.path;
  in {
    bayt.users."${config.user.name}".files = {
      "${steamPath}/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg/autoexec.cfg".text = ''
        alias +switchw "slot3; +lookatweapon"
        alias -switchw "-lookatweapon; lastinv"
        bind "X" +switchw
      '';

      "${steamPath}/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg/video.txt".text = ''
        "videoconfig"
        {
          "setting.defaultres"      "2560"
          "setting.defaultresheight" "1440"
          "setting.fullscreen"       "0"
          "setting.nowindowborder"   "1"
        }
      '';
    };
  });
}
