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

  config = lib.mkIf config.home.programs.firefox.enable {

    environment.systemPackages = with pkgs; [
      (wrapFirefox firefox-unwrapped {
        extraPolicies =
          sharedPolicies.browserPolicies
          // {
            DisableFirefoxStudies = true;
          };
      })
    ];
    hjem.users.${username} = {
      files = {
        ".config/zsh/.zprofile" = {
          text = lib.mkAfter ''
            export MOZ_ENABLE_WAYLAND=1
            export MOZ_USE_XINPUT2=1
          '';
          clobber = true;
        };
        ".mozilla/firefox/profiles.ini" = {
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
