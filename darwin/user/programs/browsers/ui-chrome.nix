{
  config,
  lib,
  ...
}: let
  sharedUi = import ../../../../lib/shared/browsers/ui-chrome.nix {};
  inherit (sharedUi) userChromeCss;
in {
  config = lib.mkIf config.user.programs.librewolf.enable {
    home-manager.users.y0usaf = {
      home.file.".librewolf/y0usaf/chrome/userChrome.css" = {
        text = userChromeCss;
      };
    };
  };
}
