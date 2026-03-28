{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.npm = {
    enable = lib.mkEnableOption "Node.js and NPM configuration";
  };
  config = lib.mkIf config.user.dev.npm.enable {
    environment.systemPackages = [
      pkgs.nodejs_20
    ];
    bayt.users."${config.user.name}".files.".config/npm/npmrc" = {
      clobber = true;
      text = ''
        prefix=${config.user.homeDirectory}/.local/share/npm
        cache=${config.user.homeDirectory}/.cache/npm
        init-module=${config.user.homeDirectory}/.config/npm/config/npm-init.js
        store-dir=${config.user.homeDirectory}/.cache/pnpm/store
      '';
    };
    systemd.tmpfiles.rules = [
      "d ${config.user.homeDirectory}/.local/share/npm 0755 ${config.user.name} ${config.user.name} - -"
      "d ${config.user.homeDirectory}/.cache/npm 0755 ${config.user.name} ${config.user.name} - -"
      "d ${config.user.homeDirectory}/.config/npm/config 0755 ${config.user.name} ${config.user.name} - -"
      "d ${config.user.homeDirectory}/.cache/pnpm/store 0755 ${config.user.name} ${config.user.name} - -"
      "d /run/user/%i/npm 0755 ${config.user.name} ${config.user.name} - -"
    ];
  };
}
