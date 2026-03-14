{
  config,
  lib,
  pkgs,
  ...
}: let
  firefoxShared = import ../../../../lib/browsers/firefox-shared.nix {inherit config lib;};
  inherit (config) user;
  userName = user.name;
in {
  imports = [
    ./ui-chrome.nix
  ];

  config = lib.mkIf user.programs.firefox.enable {
    home-manager.users."${userName}" = {
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
          ".mozilla/firefox/${userName}/chrome/userChrome.css" = {
            text = firefoxShared.userChromeCss;
          };
          ".mozilla/firefox/${userName}/chrome/userContent.css" = {
            text = firefoxShared.userContentCss;
          };
        };
      };
    };
  };
}
