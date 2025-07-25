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
    users.users.${config.user.name}.maid = {
      packages = with pkgs; [
        nodejs_20
      ];
      file = {
        xdg_config.".config/npm/npmrc".text = ''
          prefix={{home}}/.local/share/npm
          cache={{xdg_cache_home}}/npm
          init-module={{xdg_config_home}}/npm/config/npm-init.js
          store-dir={{xdg_cache_home}}/pnpm/store
        '';
        home.".local/share/bin/npm-setup" = {
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
      systemd.tmpfiles.dynamicRules = [
        "d {{home}}/.local/share/npm 0755 {{user}} {{group}} - -"
        "d {{xdg_cache_home}}/npm 0755 {{user}} {{group}} - -"
        "d {{xdg_config_home}}/npm/config 0755 {{user}} {{group}} - -"
        "d {{xdg_cache_home}}/pnpm/store 0755 {{user}} {{group}} - -"
        "d {{xdg_runtime_dir}}/npm 0755 {{user}} {{group}} - -"
      ];
    };
  };
}
