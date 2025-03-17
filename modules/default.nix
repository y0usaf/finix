{lib, ...}: {
  imports = [
    ./apps
    ./core
    ./dev
    ./ui
    # system and flake directories are intentionally excluded
    # template.nix is intentionally excluded
  ];
}
