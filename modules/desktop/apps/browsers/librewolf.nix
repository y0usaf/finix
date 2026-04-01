{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) user;
  browserShared = user.programs.browser.shared;
  inherit (user) shell;
  userName = user.name;
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
    bayt.users."${userName}" = {
      files =
        {
          ".librewolf/profiles.ini" = {
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
            clobber = true;
          };
          ".librewolf/${userName}/chrome/userChrome.css" = {
            text = browserShared.userChromeCss;
            clobber = true;
          };
          # Pywalfox native messaging host for dynamic theme updates
          ".librewolf/native-messaging-hosts/pywalfox.json".text = builtins.toJSON {
            name = "pywalfox";
            description = "Native messaging host for Pywalfox";
            path = "${pkgs.writeShellScript "pywalfox-wrapper" ''
              exec ${pywalfoxNative}/bin/pywalfox start
            ''}";
            type = "stdio";
            allowed_extensions = ["pywalfox@frewacom.org"];
          };
        }
        // lib.optionalAttrs shell.zsh.enable {
          ".config/zsh/.zprofile" = {
            text = lib.mkAfter ''
              export MOZ_ENABLE_WAYLAND=1
              export MOZ_USE_XINPUT2=1
            '';
            clobber = true;
          };
        }
        // lib.optionalAttrs shell.nushell.enable {
          ".config/nushell/login.nu" = {
            text = lib.mkAfter ''
              $env.MOZ_ENABLE_WAYLAND = "1"
              $env.MOZ_USE_XINPUT2 = "1"
            '';
            clobber = true;
          };
        };
    };
  };
}
