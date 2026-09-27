{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".local/share/cargo"
    ".local/share/rustup"
  ];
  environment.systemPackages = [
    pkgs.crane
    pkgs.rustup
    pkgs.pkg-config
    pkgs.openssl
    pkgs.gcc
  ];
}
