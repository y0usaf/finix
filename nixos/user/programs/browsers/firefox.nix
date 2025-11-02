{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../../../lib/browsers/options.nix
    ./ui-chrome.nix
  ];

  config = lib.mkIf config.user.programs.firefox.enable {
    environment.systemPackages = [
      (pkgs.wrapFirefox pkgs.firefox-unwrapped {
        extraPolicies =
          (import ./policies.nix {inherit config lib;}).browserPolicies
          // {
            DisableFirefoxStudies = true;
          };
      })
    ];
    hjem.users.${config.user.name} = {
      files =
        {
          ".mozilla/firefox/profiles.ini" = {
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
