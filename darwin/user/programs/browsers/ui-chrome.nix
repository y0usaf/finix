{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.programs.librewolf.enable {
    home-manager.users.y0usaf = {
      home.file.".librewolf/y0usaf/chrome/userChrome.css" = {
        text = (import ../../../../lib/browsers/ui-chrome.nix).userChromeCss;
      };
    };
  };
}
