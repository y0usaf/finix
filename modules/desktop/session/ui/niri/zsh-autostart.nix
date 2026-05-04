{
  config,
  lib,
  ...
}: let
  niriMarker = lib.mkAfter ''
    #niri
  '';
in {
  config = lib.mkIf config.user.ui.niri.enable {
    manzil.users."${config.user.name}".files =
      lib.optionalAttrs (lib.attrByPath ["user" "shell" "zsh" "enable"] false config) {
        ".config/zsh/.zprofile" = {
          text = niriMarker;
        };
      }
      // lib.optionalAttrs (lib.attrByPath ["user" "shell" "nushell" "enable"] false config) {
        ".config/nushell/login.nu" = {
          text = niriMarker;
        };
      };
  };
}
