{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.programs.librewolf.enable {
    usr.files.".librewolf/y0usaf/chrome/userChrome.css".text = (import ../../../../lib/browsers/ui-chrome.nix).userChromeCss;
  };
}
