{
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    (pkgs.callPackage "${flakeInputs.claude-desktop-linux}/nix/claude-desktop.nix" {})
  ];
}
