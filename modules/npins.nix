# Simple npins module
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = lib.mkIf (builtins.elem "npins" profile.features) {
    # Just install the npins package
    home.packages = with pkgs; [
      npins
    ];
  };
}
