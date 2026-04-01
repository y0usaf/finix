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
        alias +switchw "slot3"
        alias -switchw "lastinv"
        bind "G" +switchw
      '';
    };
  });
}
