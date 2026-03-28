{
  config,
  lib,
  pkgs,
  ...
}: let
  librewolfShared = import ./data/librewolf-shared.nix {inherit config lib;};
  inherit (import ./data/helpers.nix {inherit lib;}) attrsToLines prefValue;
  inherit (config) user;
  inherit (user) shell;
  userName = user.name;
  inherit (librewolfShared) profilesIni;
  pywalfoxNative = pkgs.pywalfox-native;
in {
  imports = [
    ./browser-options.nix
    ./ui-chrome.nix
  ];

  config = lib.mkIf user.programs.librewolf.enable {
    environment.systemPackages = [
      (pkgs.librewolf-bin.override {
        extraPrefs = (attrsToLines (name: value: "lockPref(\"${name}\", ${prefValue value});") librewolfShared.locked) + "\n" + (attrsToLines (name: value: "defaultPref(\"${name}\", ${prefValue value});") librewolfShared.default);
        extraPolicies = librewolfShared.browserPolicies;
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
