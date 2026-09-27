{
  config,
  pkgs,
  flakeInputs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/Claude"
  ];
  environment.systemPackages = [
    (pkgs.callPackage "${flakeInputs.claude-desktop-linux}/nix/claude-desktop.nix" {})
  ];
}
