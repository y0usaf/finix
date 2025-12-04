{...}: {
  imports = [
    ./options.nix
    ./core
    ./shell
    ./dev
    ./tools
    ./services
    ./ui
    ./programs
    ./appearance/wallust
    ../../../configs/users/y0usaf-darwin.nix
  ];
}
