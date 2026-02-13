{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.programs.librewolf.enable {
    home-manager.users.${config.user.name} = {
      home.file.".librewolf/${config.user.name}/chrome/userChrome.css" = {
        text = (import ../../../../lib/browsers/ui-chrome.nix).userChromeCss;
      };
    };
  };
}
