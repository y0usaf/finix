{
  config,
  lib,
  pkgs,
  ...
}: let
  librewolfShared = import ../../../../lib/browsers/librewolf-shared.nix {inherit config lib;};
  inherit (import ../../../../lib/browsers/helpers.nix {inherit lib;}) attrsToLines prefValue;
  inherit (config) user;
  userName = user.name;
in {
  imports = [
    ./ui-chrome.nix
  ];

  config = lib.mkIf user.programs.librewolf.enable {
    home-manager.users."${userName}" = {
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
          ".librewolf/${userName}/user.js" = {
            text =
              ''
                user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
              ''
              + attrsToLines (name: value: "lockPref(\"${name}\", ${prefValue value});") librewolfShared.locked
              + "\n"
              + (lib.concatMapAttrsStringSep "\n" (name: value: "defaultPref(\"${name}\", ${prefValue value});") librewolfShared.default);
          };
        };
      };
    };
  };
}
