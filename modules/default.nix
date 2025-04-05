{lib, ...}: {
  imports = [
    ./home
    # system and flake directories are intentionally excluded
    # template.nix is intentionally excluded
  ];
}