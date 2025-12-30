{
  config,
  lib,
  pkgs,
  ...
}: let
  firefoxShared = import ../../../../lib/browsers/firefox-shared.nix {inherit config lib;};
in {
  imports = [
    ../../../../lib/browsers/options.nix
    ./ui-chrome.nix
  ];

  config = lib.mkIf config.user.programs.firefox.enable {
    home-manager.users.y0usaf = {
      home.packages = [
        (pkgs.wrapFirefox pkgs.firefox-unwrapped {
          extraPolicies = firefoxShared.browserPolicies;
        })
      ];
      home.file.".mozilla/firefox/profiles.ini" = {
        text = lib.generators.toINI {} firefoxShared.profilesIni;
      };
    };
  };
}
