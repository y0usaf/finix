{
  config,
  lib,
  ...
}: let
  sharedUi = import ../../../../lib/shared/browsers/ui-chrome.nix {};
  usr = config.hjem.users.${config.user.name};
in {
  config = lib.mkIf config.user.programs.librewolf.enable {
    hjem.users.${config.user.name}.files.".librewolf/y0usaf/chrome/userChrome.css".text = sharedUi.userChromeCss;
  };
}
