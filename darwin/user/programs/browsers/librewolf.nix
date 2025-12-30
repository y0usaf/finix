{
  config,
  lib,
  pkgs,
  ...
}: let
  librewolfShared = import ../../../../lib/browsers/librewolf-shared.nix {inherit config lib;};

  prefValue = pref:
    builtins.toJSON (
      if builtins.isBool pref || builtins.isInt pref || builtins.isString pref
      then pref
      else builtins.toString pref
    );

  prefsToJs = attrs: lib.concatMapAttrsStringSep "\n" (name: value: "lockPref(\"${name}\", ${prefValue value});") attrs;
in {
  imports = [
    ../../../../lib/browsers/options.nix
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
            text = lib.generators.toINI {} librewolfShared.profilesIni;
          };
          ".librewolf/distribution/policies.json" = {
            text = builtins.toJSON {
              policies = librewolfShared.browserPolicies;
            };
          };
          ".librewolf/y0usaf/user.js" = {
            text =
              ''
                user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
              ''
              + prefsToJs librewolfShared.locked
              + "\n"
              + (lib.concatMapAttrsStringSep "\n" (name: value: "defaultPref(\"${name}\", ${prefValue value});") librewolfShared.default);
          };
        };
      };
    };
  };
}
