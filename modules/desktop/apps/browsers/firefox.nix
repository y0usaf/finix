{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) user;
  browserShared = user.programs.browser.shared;
  userName = user.name;
  profilesIni = {
    Profile0 = {
      Name = "default";
      IsRelative = 1;
      Path = "default";
      Default = 1;
    };
    General = {
      StartWithLastProfile = 1;
      Version = 2;
    };
  };
in {
  config = lib.mkIf user.programs.firefox.enable {
    environment.systemPackages = [
      (pkgs.wrapFirefox pkgs.firefox-unwrapped {
        extraPolicies = browserShared.policies // {DisableFirefoxStudies = true;};
      })
    ];
    manzil.users."${userName}" = {
      files = {
        ".mozilla/firefox/profiles.ini" = {
          generator = lib.generators.toINI {};
          value =
            profilesIni
            // {
              Profile0 =
                profilesIni.Profile0
                // {
                  Path = userName;
                };
            };
        };
        ".mozilla/firefox/${userName}/chrome/userChrome.css" = {
          text = browserShared.userChromeCss;
        };
      };
    };
  };
}
