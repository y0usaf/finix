{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (config) user;
  browserShared = user.programs.browser.shared;
  userName = user.name;
  glideConfig = ".config/glide/glide";
  glideNativeHosts = ".glide-browser/native-messaging-hosts";
  pywalfoxNative = pkgs.pywalfox-native;
  prefValue = pref:
    builtins.toJSON (
      if builtins.isBool pref || builtins.isInt pref || builtins.isString pref
      then pref
      else builtins.toString pref
    );
  attrsToLines = f: attrs: lib.concatMapAttrsStringSep "\n" f attrs;
  lockedPrefs = builtins.removeAttrs browserShared.lockedPrefs ["browser.nova.enabled"];
  policies =
    browserShared.policies
    // {
      DisableFirefoxAccounts = false;
      ExtensionSettings = builtins.removeAttrs browserShared.policies.ExtensionSettings ["vimium-c@gdh1995.cn"];
    };
  glide = pkgs.wrapFirefox (pkgs.callPackage "${flakeInputs.glide-browser}/package.nix" {}) {
    pname = "glide-browser";
    extraPrefs =
      (attrsToLines (name: value: "lockPref(\"${name}\", ${prefValue value});") lockedPrefs)
      + "\n"
      + (attrsToLines (name: value: "defaultPref(\"${name}\", ${prefValue value});") browserShared.defaultPrefs);
    extraPolicies = policies;
  };
in {
  config = lib.mkIf user.programs.glide.enable {
    environment.systemPackages = [glide pywalfoxNative];
    manzil.users."${userName}".files = {
      "${glideConfig}/profiles.ini" = {
        generator = lib.generators.toINI {};
        value = {
          Profile0 = {
            Name = "default";
            IsRelative = 1;
            Path = userName;
            Default = 1;
          };
          General = {
            StartWithLastProfile = 1;
            Version = 2;
          };
        };
      };
      "${glideNativeHosts}/pywalfox.json" = {
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
}
