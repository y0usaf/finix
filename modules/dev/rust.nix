{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.rust = {
    enable = lib.mkEnableOption "Rust development environment";
  };

  config = lib.mkIf config.user.dev.rust.enable {
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
  };
}
