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
    home-manager.users.y0usaf = {
      home = {
        packages = [
          pkgs.librewolf
        ];
        file = {
          ".librewolf/profiles.ini" = {
            text = lib.generators.toINI {} {
              Profile0 = {
                Name = "y0usaf";
                IsRelative = 1;
                Path = "y0usaf";
                Default = 1;
              };
              General = {
                StartWithLastProfile = 1;
                Version = 2;
              };
            };
          };
          ".librewolf/distribution/policies.json" = {
            text = builtins.toJSON {
              policies =
                (import ./policies.nix {inherit config lib;}).browserPolicies
                // {
                  DisableFirefoxAccounts = false;
                };
            };
          };
          ".librewolf/y0usaf/user.js" = {
            text =
              ''
                user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
              ''
              + (lib.concatMapAttrsStringSep "\n" (name: value: "lockPref(\"${name}\", ${builtins.toJSON (
                if builtins.isBool value || builtins.isInt value || builtins.isString value
                then value
                else builtins.toString value
              )});") (import ./prefs.nix {inherit config lib;}).locked)
              + "\n"
              + (lib.concatMapAttrsStringSep "\n" (name: value: "defaultPref(\"${name}\", ${builtins.toJSON (
                if builtins.isBool value || builtins.isInt value || builtins.isString value
                then value
                else builtins.toString value
              )});") (import ./prefs.nix {inherit config lib;}).default);
          };
        };
      };
    };
  };
}
