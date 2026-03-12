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
      pkgs.rustup
      pkgs.rust-analyzer
      pkgs.pkg-config
      pkgs.openssl
      pkgs.gcc
      pkgs.cargo
    ];

    systemd.tmpfiles.rules = [
      "d ${config.user.homeDirectory}/.local/share/cargo 0755 ${config.user.name} ${config.user.name} - -"
      "d ${config.user.homeDirectory}/.local/share/rustup 0755 ${config.user.name} ${config.user.name} - -"
    ];
  };
}
