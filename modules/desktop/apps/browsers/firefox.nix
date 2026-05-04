{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) user;
  browserShared = user.programs.browser.shared;
  inherit (user) shell;
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
      files =
        {
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
        }
        // lib.optionalAttrs shell.zsh.enable {
          ".config/zsh/.zprofile" = {
            text = lib.mkAfter ''
              export MOZ_ENABLE_WAYLAND=1
              export MOZ_USE_XINPUT2=1
            '';
          };
        }
        // lib.optionalAttrs shell.nushell.enable {
          ".config/nushell/login.nu" = {
            text = lib.mkAfter ''
              $env.MOZ_ENABLE_WAYLAND = "1"
              $env.MOZ_USE_XINPUT2 = "1"
            '';
          };
        };
    };
  };
}
