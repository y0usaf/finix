# modules/home/gaming/marvel-rivals/default.nix
# Marvel Rivals game configuration
{
  lib,
  ...
}: {
  imports = [
    ./engine.nix
    ./gameusersettings.nix
    ./marvelusersettings.nix
  ];
}