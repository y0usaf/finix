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
  config = {
    # Add Cursor IDE package
    home.packages = [
      pkgs.claude-code
    ];
  };
}
