{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) toJSON isBool isInt isString toString;

  prefs = import ./prefs.nix {inherit config lib;};

  prefValue = pref:
    toJSON (
      if isBool pref || isInt pref || isString pref
      then pref
      else toString pref
    );

  attrsToLines = f: attrs: lib.concatMapAttrsStringSep "\n" f attrs;
in {
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
              + (attrsToLines (name: value: "lockPref(\"${name}\", ${prefValue value});") prefs.locked)
              + "\n"
              + (attrsToLines (name: value: "defaultPref(\"${name}\", ${prefValue value});") prefs.default);
          };
        };
      };
    };
  };
}
