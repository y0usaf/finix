{
  config,
  lib,
  pkgs,
  ...
}: let
  firefoxShared = import ../../../../lib/browsers/firefox-shared.nix {inherit config lib;};
  inherit (config) user;
  userName = user.name;
  inherit (firefoxShared) profilesIni;
in {
  imports = [
    ../../../../lib/browsers/options.nix
    ./ui-chrome.nix
  ];

  config = lib.mkIf user.programs.firefox.enable {
    environment.systemPackages = [
      (pkgs.wrapFirefox pkgs.firefox-unwrapped {
        extraPolicies = firefoxShared.browserPolicies;
      })
    ];
    hjem.users."${userName}" = {
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
            clobber = true;
          };
          ".mozilla/firefox/${userName}/chrome/userChrome.css" = {
            text = firefoxShared.userChromeCss;
            clobber = true;
          };
          ".mozilla/firefox/${userName}/chrome/userContent.css" = {
            text = firefoxShared.userContentCss;
            clobber = true;
          };
        }
        // lib.optionalAttrs user.shell.zsh.enable {
          ".config/zsh/.zprofile" = {
            text = lib.mkAfter ''
              export MOZ_ENABLE_WAYLAND=1
              export MOZ_USE_XINPUT2=1
            '';
            clobber = true;
          };
        }
        // lib.optionalAttrs user.shell.nushell.enable {
          ".config/nushell/login.nu" = {
            text = lib.mkAfter ''
              $env.MOZ_ENABLE_WAYLAND = "1"
              $env.MOZ_USE_XINPUT2 = "1"
            '';
            clobber = true;
          };
        };
    };
  };
}
