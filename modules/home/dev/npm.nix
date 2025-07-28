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
    hjem.users.${config.user.name} = {
      packages = with pkgs; [
        nodejs_20
      ];
      files = {
        ".config/npm/npmrc" = {
          clobber = true;
          text = ''
            prefix={{home}}/.local/share/npm
            cache={{xdg_cache_home}}/npm
            init-module={{xdg_config_home}}/npm/config/npm-init.js
            store-dir={{xdg_cache_home}}/pnpm/store
          '';
        };
        ".local/share/bin/npm-setup" = {
          clobber = true;
          text = ''
            mkdir -p {{home}}/.local/share/npm
            mkdir -p {{xdg_cache_home}}/npm
            mkdir -p {{xdg_config_home}}/npm/config
            mkdir -p {{xdg_cache_home}}/pnpm/store
            mkdir -p "{{xdg_runtime_dir}}/npm"
          '';
          executable = true;
        };
      };
    };
    systemd.tmpfiles.rules = [
      "d ${config.user.homeDirectory}/.local/share/npm 0755 ${config.user.name} ${config.user.name} - -"
      "d ${config.user.homeDirectory}/.cache/npm 0755 ${config.user.name} ${config.user.name} - -"
      "d ${config.user.homeDirectory}/.config/npm/config 0755 ${config.user.name} ${config.user.name} - -"
      "d ${config.user.homeDirectory}/.cache/pnpm/store 0755 ${config.user.name} ${config.user.name} - -"
      "d /run/user/1000/npm 0755 ${config.user.name} ${config.user.name} - -"
    ];
  };
}
