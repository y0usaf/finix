{
  config,
  lib,
  pkgs,
  ...
}: let
  librewolfShared = import ../../../../lib/browsers/librewolf-shared.nix {inherit config lib;};
  helpers = import ../../../../lib/browsers/helpers.nix {inherit lib;};
in {
  imports = [
    ../../../../lib/browsers/options.nix
    ./ui-chrome.nix
  ];

  config = lib.mkIf config.user.programs.librewolf.enable {
    environment.systemPackages = [
      (pkgs.librewolf-bin.override {
        extraPrefs = (helpers.attrsToLines (name: value: "lockPref(\"${name}\", ${helpers.prefValue value});") librewolfShared.locked) + "\n" + (helpers.attrsToLines (name: value: "defaultPref(\"${name}\", ${helpers.prefValue value});") librewolfShared.default);
        extraPolicies = librewolfShared.browserPolicies;
      })
      pkgs.pywalfox-native
    ];
    hjem.users."${config.user.name}" = {
      files =
        {
          ".librewolf/profiles.ini" = {
            generator = lib.generators.toINI {};
            value =
              librewolfShared.profilesIni
              // {
                Profile0 =
                  librewolfShared.profilesIni.Profile0
                  // {
                    Name = "default";
                    Path = config.user.name;
                  };
              };
            clobber = true;
          };
          # Pywalfox native messaging host for dynamic theme updates
          ".librewolf/native-messaging-hosts/pywalfox.json".text = builtins.toJSON {
            name = "pywalfox";
            description = "Native messaging host for Pywalfox";
            path = "${pkgs.writeShellScript "pywalfox-wrapper" ''
              exec ${pkgs.pywalfox-native}/bin/pywalfox start
            ''}";
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
