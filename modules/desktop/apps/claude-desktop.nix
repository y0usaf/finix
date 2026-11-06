{
  pkgs,
  flakeInputs,
  ...
}: {
  user.persist.directories = [".config/Claude"];
  environment.systemPackages = [(pkgs.callPackage "${flakeInputs.claude-desktop-linux}/nix/claude-desktop.nix" {})];
}
