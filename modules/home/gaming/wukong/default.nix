# modules/home/gaming/wukong/default.nix
# Black Myth: Wukong game configuration
{
  lib,
  ...
}: {
  imports = [
    ./engine.nix
  ];
}