{
  config,
  lib,
  ...
}: let
  zshEnabled = lib.attrByPath ["user" "shell" "zsh" "enable"] false config;
  nushellEnabled = lib.attrByPath ["user" "shell" "nushell" "enable"] false config;
  niriMarker = lib.mkAfter ''
    #niri
  '';
in {
  config = lib.mkIf config.user.ui.niri.enable {
    bayt.users."${config.user.name}".files =
      lib.optionalAttrs zshEnabled {
        ".config/zsh/.zprofile" = {
          text = niriMarker;
        };
      }
      // lib.optionalAttrs nushellEnabled {
        ".config/nushell/login.nu" = {
          text = niriMarker;
        };
      };
  };
}
