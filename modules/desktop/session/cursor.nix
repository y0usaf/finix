{
  config,
  lib,
  inputPackages,
  ...
}: let
  xcursorSize = 18;
  cursorPackage = inputPackages.cursors.deepin-dark;
in {
  options.user.appearance.hyprcursorSize = lib.mkOption {
    type = lib.types.int;
    default = 24;
    description = "Base Hyprcursor size at user.appearance.dpi.";
  };

  config.environment = {
    systemPackages = cursorPackage.cursorPackages or [cursorPackage];
    variables = cursorPackage.mkCursorSessionVariables {
      inherit xcursorSize;
      inherit (config.user.appearance) hyprcursorSize;
    };
  };
}
