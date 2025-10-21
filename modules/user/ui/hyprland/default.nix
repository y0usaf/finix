_: {
  imports = [
    ./options.nix
    ./config.nix
    ./variables.nix # Variables first
    ./keybindings.nix
    ./core.nix
    ./monitors.nix
    ./window-rules.nix
    ./ags-integration.nix
    ./quickshell-integration.nix
    ./portals.nix
  ];
}
