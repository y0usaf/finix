{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.bun = {
    enable = lib.mkEnableOption "Bun runtime and package manager";
  };
  config = lib.mkIf config.user.dev.bun.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".local/share/bun"
    ];
    environment.systemPackages = [
      pkgs.bun
    ];
    manzil.users."${config.user.name}".files.".config/bun/bunfig.toml" = {
      generator = (pkgs.formats.toml {}).generate "nix-generated.toml";
      value.install = {
        cache_dir = "${config.user.homeDirectory}/.cache/bun";
        global_dir = "${config.user.homeDirectory}/.local/share/bun";
      };
    };
  };
}
