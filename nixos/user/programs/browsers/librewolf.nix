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
    ../../../../lib/browsers/options.nix
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
      pkgs.pywalfox-native
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
          # Pywalfox native messaging host for dynamic theme updates
          ".librewolf/native-messaging-hosts/pywalfox.json".text = let
            pywalfoxWrapper = pkgs.writeShellScript "pywalfox-wrapper" ''
              exec ${pkgs.pywalfox-native}/bin/pywalfox start
            '';
          in
            builtins.toJSON {
              name = "pywalfox";
              description = "Native messaging host for Pywalfox";
              path = "${pywalfoxWrapper}";
              type = "stdio";
              allowed_extensions = ["pywalfox@frewacom.org"];
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
