{config, ...}: let
  homeDir = config.user.homeDirectory;
in {
  user.paths = {
    wallpapers.static.path = "${homeDir}/DCIM/Wallpapers/32_9/";
    bookmarks = [
      "file://${homeDir}/Downloads Downloads"
      "file://${homeDir}/Documents Documents"
      "file://${homeDir}/dev dev"
      "file://${homeDir}/cu-workbench/repos CookUnity"
      "file://${homeDir}/Music Music"
      "file://${homeDir}/DCIM Pictures"
      "file://${homeDir}/nixos NixOS"
      "file:///tmp tmp"
    ];
  };
}
