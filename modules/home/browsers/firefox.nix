{
  config,
  lib,
  pkgs,
  ...
}: let
  username = config.user.name;
  sharedPolicies = import ./shared-policies.nix { inherit config lib; };
in {
  imports = [
    ./config.nix
    ./performance.nix
    ./ui-chrome.nix
  ];

  config = lib.mkIf config.home.programs.firefox.enable {
    hjem.users.${username} = {
      packages = with pkgs; [
        (wrapFirefox firefox-unwrapped {
          extraPolicies = sharedPolicies.browserPolicies // {
            DisableFirefoxStudies = true;
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
      };
    };
  };
}
