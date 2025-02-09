{
  config,
  pkgs,
  lib,
  profile,
  inputs,
  ...
}: let
  version = with builtins; head (match ".*v([0-9.]+).*" (readFile "${inputs.noi}/package.json"));
in {
  config = {
    home.packages = [
      (pkgs.appimageTools.wrapType2 {
        name = "noi";
        version = "0.4.0";
        src = pkgs.fetchurl {
          url = "https://github.com/lencx/Noi/releases/download/v0.4.0/Noi_linux_0.4.0.AppImage";
          sha256 = "0w03wjrykhs7l7q7hg7dk3brppjagdhgr9x6rly7whi8j4r3a0k7";
        };
      })
    ];

    xdg.desktopEntries = {
      noi = {
        name = "Noi";
        exec = "noi %U";
        terminal = false;
        categories = ["Development" "Utility" "AI"];
        comment = "AI Chat Client";
        icon = "noi";
      };
    };
  };
}
