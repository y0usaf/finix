{
  config,
  lib,
  ...
}: let
  zshEnabled = lib.attrByPath ["user" "shell" "zsh" "enable"] false config;
  nushellEnabled = lib.attrByPath ["user" "shell" "nushell" "enable"] false config;
in {
  config = lib.mkIf config.user.ui.niri.enable {
    bayt.users."${config.user.name}".files =
      lib.optionalAttrs zshEnabled {
        ".config/zsh/.zprofile" = {
          text = lib.mkAfter ''
            #niri
          '';
        };
      }
      // lib.optionalAttrs nushellEnabled {
        ".config/nushell/login.nu" = {
          text = lib.mkAfter ''
            #niri
          '';
        };
      };
  };
}
