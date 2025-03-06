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
    # Add Cursor IDE package with specific version
    home.packages = let
      # Use a specific version of nixpkgs that has cursor 0.42.4
      pinnedPkgs =
        import (builtins.fetchGit {
          # Use a known commit that has cursor 0.42.4
          url = "https://github.com/NixOS/nixpkgs";
          ref = "nixos-23.11"; # Using a stable branch
          rev = "ce62a1161fb338860874468db35cd3e05a6b51eb"; # The commit hash you found earlier
        }) {
          # Use a hardcoded system value
          system = "x86_64-linux";
          config = {allowUnfree = true;}; # Cursor is likely unfree
        };
    in [
      # Use cursor from the pinned version of nixpkgs
      pinnedPkgs.cursor
    ];
  };
}
