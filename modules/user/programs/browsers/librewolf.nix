{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatMapAttrsStringSep;
  inherit (builtins) toJSON isBool isInt isString toString;

  # Import preferences
  prefs = import ./prefs.nix {inherit config lib;};

  # Convert preference value to JSON
  prefValue = pref:
    toJSON (
      if isBool pref || isInt pref || isString pref
      then pref
      else toString pref
    );

  # Convert attrs to JS pref calls
  attrsToLines = f: attrs: concatMapAttrsStringSep "\n" f attrs;
in {
  imports = [
    ./config.nix
    ./ui-chrome.nix
  ];

  config = lib.mkIf config.user.programs.librewolf.enable {
    environment.systemPackages = [
      (pkgs.librewolf-bin.override {
        extraPrefs = (attrsToLines (name: value: "lockPref(\"${name}\", ${prefValue value});") prefs.locked) + "\n" + (attrsToLines (name: value: "defaultPref(\"${name}\", ${prefValue value});") prefs.default);
        extraPolicies =
          (import ./policies.nix {inherit config lib;}).browserPolicies
          // {
            DisableFirefoxAccounts = false;
          };
      })
    ];
    hjem.users.${config.user.name} = {
      files =
        {
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
