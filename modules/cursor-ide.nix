#===============================================================================
#                      🖋️ Code Cursor IDE Configuration 🖋️
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = lib.mkIf (builtins.elem "development" profile.features) {
    # Add Code Cursor package
    home.packages = with pkgs; [
      code-cursor
    ];
  };
}
