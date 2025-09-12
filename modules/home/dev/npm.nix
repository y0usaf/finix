{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.dev.npm;
in {
  options.home.dev.npm = {
    enable = lib.mkEnableOption "Node.js and NPM configuration";
  };
  config = lib.mkIf cfg.enable {
    usr = {
      packages = with pkgs; [
        nodejs_20
      ];
      files = {
        ".config/npm/npmrc" = {
          clobber = true;
          text = ''
            prefix=${config.user.dataDirectory}/npm
            cache=${config.user.cacheDirectory}/npm
            init-module=${config.user.configDirectory}/npm/config/npm-init.js
            store-dir=${config.user.cacheDirectory}/pnpm/store
          '';
        };
      };
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
