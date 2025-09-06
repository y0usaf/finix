{...}: {
  imports = [
    ./format-nix.nix
    ./polkit-agent.nix
    ./polkit-gnome.nix
    ./ssh.nix
    ./syncthing.nix
  ];
}
