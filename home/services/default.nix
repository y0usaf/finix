{...}: {
  imports = [
    ./format-nix.nix
    ./hyprland-config-watcher.nix
    ./nixos-git-sync.nix
    ./polkit-agent.nix
    ./polkit-gnome.nix
    ./ssh.nix
    ./syncthing.nix
  ];
}
