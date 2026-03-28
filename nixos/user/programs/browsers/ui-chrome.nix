{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.programs.librewolf.enable {
    bayt.users."${config.user.name}".files.".librewolf/y0usaf/chrome/userChrome.css".text = (import ./data/ui-chrome.nix).userChromeCss;
  };
}
