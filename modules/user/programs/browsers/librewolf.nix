{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./config.nix
    ./ui-chrome.nix
  ];

  config = lib.mkIf config.user.programs.librewolf.enable {
    environment.systemPackages = [
      (pkgs.wrapFirefox pkgs.librewolf-unwrapped {
        extraPolicies =
          (import ./policies.nix {inherit config lib;}).browserPolicies
          // {
            DisableFirefoxAccounts = false;
          };
      })
    ];
    hjem.users.${config.user.name} = {
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
              Path = config.user.name;
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
