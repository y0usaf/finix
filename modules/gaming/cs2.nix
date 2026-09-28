{config, ...}: {
  manzil.users."${config.user.name}".files = {
    "${config.user.paths.steam}/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg/autoexec.cfg".text = ''
      alias +switchw "slot3; +lookatweapon"
      alias -switchw "-lookatweapon; lastinv"
      bind "[" +switchw
    '';

    "${config.user.paths.steam}/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg/video.txt".text = ''
      "videoconfig"
      {
        "setting.defaultres"      "2560"
        "setting.defaultresheight" "1440"
        "setting.fullscreen"       "0"
        "setting.nowindowborder"   "1"
      }
    '';
  };
}
