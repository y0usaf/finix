{
  config,
  lib,
  ...
}: let
  sharedUi = import ../../../../lib/shared/browsers/ui-chrome.nix {};
in {
  config = lib.mkIf config.user.programs.librewolf.enable {
    usr.files.".librewolf/y0usaf/chrome/userChrome.css".text = sharedUi.userChromeCss;
  };
}
