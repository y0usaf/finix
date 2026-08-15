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
    environment.systemPackages = [
      pkgs.bun
    ];
    manzil.users."${config.user.name}".files.".config/bun/bunfig.toml" = {
      generator = config.lib.generators.toTOML;
      value.install = {
        cache_dir = "${config.user.homeDirectory}/.cache/bun";
        global_dir = "${config.user.homeDirectory}/.local/share/bun";
      };
    };
  };
}
