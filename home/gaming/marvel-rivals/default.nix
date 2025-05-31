# modules/home/gaming/marvel-rivals/default.nix
# Marvel Rivals game configuration
{...}: {
  imports = [
    ./engine.nix
    ./gameusersettings.nix
    ./marvelusersettings.nix
  ];
}
