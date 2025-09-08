{
  config,
  lib,
  pkgs,
  ...
}: let
  username = config.user.name;
  sharedPolicies = import ./policies.nix {inherit config lib;};
in {
  imports = [
    ./config.nix
    ./ui-chrome.nix
  ];

  config = lib.mkIf config.home.programs.librewolf.enable {
    hjem.users.${username} = {
      packages = with pkgs; [
        (wrapFirefox librewolf-unwrapped {
          extraPolicies =
            sharedPolicies.browserPolicies
            // {
              DisableFirefoxAccounts = false;
            };
        })
      ];
      files = {
        ".config/zsh/.zprofile" = {
          text = lib.mkAfter ''
            export MOZ_ENABLE_WAYLAND=1
            export MOZ_USE_XINPUT2=1
          '';
          clobber = true;
        };
        ".librewolf/profiles.ini" = {
          generator = lib.generators.toINI {};
          value = {
            Profile0 = {
              Name = "default";
              IsRelative = 1;
              Path = username;
              Default = 1;
            };
            General = {
              StartWithLastProfile = 1;
              Version = 2;
            };
          };
          clobber = true;
        };
      };
    };
  };
}
