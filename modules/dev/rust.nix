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
    environment.systemPackages = [
      pkgs.crane
      pkgs.rustup
      pkgs.pkg-config
      pkgs.openssl
      pkgs.gcc
    ];

  };
}
