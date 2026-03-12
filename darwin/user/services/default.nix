{config, ...}: {
  imports = [
    ./syncthing.nix
    ./ssh
    ./aerospace.nix
  ];

  home-manager.users."${config.user.name}".home.stateVersion = "24.11";
}
