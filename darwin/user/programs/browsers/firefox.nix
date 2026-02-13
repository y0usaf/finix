{
  config,
  lib,
  pkgs,
  ...
}: let
  firefoxShared = import ../../../../lib/browsers/firefox-shared.nix {inherit config lib;};
in {
  imports = [
    ./ui-chrome.nix
  ];

  config = lib.mkIf config.user.programs.firefox.enable {
    home-manager.users.${config.user.name} = {
      home = {
        packages = [
          (pkgs.wrapFirefox pkgs.firefox-unwrapped {
            extraPolicies = firefoxShared.browserPolicies;
          })
        ];
        file = {
          ".mozilla/firefox/profiles.ini" = {
            text = lib.generators.toINI {} firefoxShared.profilesIni;
          };
          ".mozilla/firefox/${config.user.name}/chrome/userChrome.css" = {
            text = firefoxShared.userChromeCss;
          };
          ".mozilla/firefox/${config.user.name}/chrome/userContent.css" = {
            text = firefoxShared.userContentCss;
          };
        };
      };
    };
  };
}
