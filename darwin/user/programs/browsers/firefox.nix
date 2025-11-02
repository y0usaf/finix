{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../../lib/browsers/options.nix
    ./ui-chrome.nix
  ];

  config = lib.mkIf config.user.programs.firefox.enable {
    home-manager.users.y0usaf = {
      home.packages = [
        (pkgs.wrapFirefox pkgs.firefox-unwrapped {
          extraPolicies =
            (import ./policies.nix {inherit config lib;}).browserPolicies
            // {
              DisableFirefoxStudies = true;
            };
        })
      ];
      home.file.".mozilla/firefox/profiles.ini" = {
        text = lib.generators.toINI {} {
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
      };
    };
  };
}
