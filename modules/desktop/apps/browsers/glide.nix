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
  # Profile root is XDG ~/.config/glide/glide (MOZ_APP_BASENAME=glide, per the
  # upstream hm-module); native messaging hosts stay at the legacy
  # ~/.glide-browser (nsXREDirProvider patch). Independent of LibreWolf's
  # ~/.librewolf, so both browsers run side by side.
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
  # Glide ships its own chrome look: skip the shared userChrome.css and the
  # Nova lock it depends on, leaving browser.nova.enabled at Glide's default.
  lockedPrefs = builtins.removeAttrs browserShared.lockedPrefs ["browser.nova.enabled"];
  # Glide's own modal keys and hints replace Vimium-C.
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
