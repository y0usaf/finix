{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) user;
  browserShared = user.programs.browser.shared;
  userName = user.name;
  # LibreWolf's native (non-Flatpak) XDG layout keeps both its profile
  # registry and native messaging hosts below this directory.  Keep this
  # separate from Firefox, which still uses ~/.mozilla.
  librewolfConfig = ".config/librewolf/librewolf";
  pywalfoxNative = pkgs.pywalfox-native;
  prefValue = pref:
    builtins.toJSON (
      if builtins.isBool pref || builtins.isInt pref || builtins.isString pref
      then pref
      else builtins.toString pref
    );
  attrsToLines = f: attrs: lib.concatMapAttrsStringSep "\n" f attrs;
  profilesIni = {
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
in {
  config = lib.mkIf user.programs.librewolf.enable {
    environment.systemPackages = [
      (pkgs.librewolf-bin.override {
        extraPrefs =
          (attrsToLines (name: value: "lockPref(\"${name}\", ${prefValue value});") browserShared.lockedPrefs)
          + "\n"
          + (attrsToLines (name: value: "defaultPref(\"${name}\", ${prefValue value});") browserShared.defaultPrefs);
        extraPolicies = browserShared.policies // {DisableFirefoxAccounts = false;};
      })
      pywalfoxNative
    ];
    manzil.users."${userName}" = {
      files = {
        "${librewolfConfig}/profiles.ini" = {
          generator = lib.generators.toINI {};
          value =
            profilesIni
            // {
              Profile0 =
                profilesIni.Profile0
                // {
                  Name = "default";
                  Path = userName;
                };
            };
        };
        "${librewolfConfig}/${userName}/chrome/userChrome.css" = {
          text = browserShared.userChromeCss;
        };
        # Pywalfox native messaging host for dynamic theme updates
        "${librewolfConfig}/native-messaging-hosts/pywalfox.json" = {
          generator = lib.generators.toJSON {};
          value = {
            name = "pywalfox";
            description = "Native messaging host for Pywalfox";
            path = "${pkgs.writeShellScript "pywalfox-wrapper" ''
              exec ${pywalfoxNative}/bin/pywalfox start
            ''}";
            type = "stdio";
            allowed_extensions = ["pywalfox@frewacom.org"];
          };
        };
      };
    };
  };
}
