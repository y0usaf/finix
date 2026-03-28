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
    bayt.users."${config.user.name}".files.".config/bun/bunfig.toml" = {
      clobber = true;
      text = ''
        [install]
        cache_dir = "${config.user.homeDirectory}/.cache/bun"
        global_dir = "${config.user.homeDirectory}/.local/share/bun"
      '';
    };
    systemd.tmpfiles.rules = [
      "d ${config.user.homeDirectory}/.local/share/bun 0755 ${config.user.name} ${config.user.name} - -"
      "d ${config.user.homeDirectory}/.cache/bun 0755 ${config.user.name} ${config.user.name} - -"
      "d ${config.user.homeDirectory}/.config/bun 0755 ${config.user.name} ${config.user.name} - -"
      "d /run/user/%i/bun 0755 ${config.user.name} ${config.user.name} - -"
    ];
  };
}
