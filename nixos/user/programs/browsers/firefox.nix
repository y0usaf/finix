{
  config,
  lib,
  pkgs,
  ...
}: let
  firefoxShared = import ../../../../lib/browsers/firefox-shared.nix {inherit config lib;};

  profilesIni =
    firefoxShared.profilesIni
    // {
      Profile0 =
        firefoxShared.profilesIni.Profile0
        // {
          Path = config.user.name;
        };
    };
in {
  imports = [
    ../../../../lib/browsers/options.nix
    ./ui-chrome.nix
  ];

  config = lib.mkIf config.user.programs.firefox.enable {
    environment.systemPackages = [
      (pkgs.wrapFirefox pkgs.firefox-unwrapped {
        extraPolicies = firefoxShared.browserPolicies;
      })
    ];
    hjem.users.${config.user.name} = {
      files =
        {
          ".mozilla/firefox/profiles.ini" = {
            generator = lib.generators.toINI {};
            value = profilesIni;
            clobber = true;
          };
        }
        // lib.optionalAttrs config.user.shell.zsh.enable {
          ".config/zsh/.zprofile" = {
            text = lib.mkAfter ''
              export MOZ_ENABLE_WAYLAND=1
              export MOZ_USE_XINPUT2=1
            '';
            clobber = true;
          };
        };
    };
  };
}
