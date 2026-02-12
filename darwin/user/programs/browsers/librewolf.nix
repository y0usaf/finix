{
  config,
  lib,
  pkgs,
  ...
}: let
  librewolfShared = import ../../../../lib/browsers/librewolf-shared.nix {inherit config lib;};
  helpers = import ../../../../lib/browsers/helpers.nix {inherit lib;};

  prefsToJs = attrs: helpers.attrsToLines (name: value: "lockPref(\"${name}\", ${helpers.prefValue value});") attrs;
in {
  imports = [
    ./ui-chrome.nix
  ];

  config = lib.mkIf config.user.programs.librewolf.enable {
    home-manager.users.${config.user.name} = {
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
          ".librewolf/${config.user.name}/user.js" = {
            text =
              ''
                user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
              ''
              + prefsToJs librewolfShared.locked
              + "\n"
              + (lib.concatMapAttrsStringSep "\n" (name: value: "defaultPref(\"${name}\", ${helpers.prefValue value});") librewolfShared.default);
          };
        };
      };
    };
  };
}
