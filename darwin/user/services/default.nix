{...}: {
  imports = [
    ./syncthing.nix
    ./ssh
    ./aerospace.nix
  ];

  home-manager.users.y0usaf.home.stateVersion = "24.11";
}
