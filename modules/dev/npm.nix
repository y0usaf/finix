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
      pkgs.nodejs
    ];
    # ~/.config/npm/npmrc is deliberately NOT managed by manzil.
    # `npm login` writes the registry auth token into its userconfig, and a
    # manzil file is a read-only store symlink, so every login failed with
    # EACCES. npm now uses its own default userconfig (~/.npmrc); the prefix,
    # cache and init-module settings it used to carry live in
    # core/user/session/xdg.nix as NPM_CONFIG_* variables. Do not reintroduce
    # a managed npmrc. `pnpm config set store-dir ~/.cache/pnpm/store` holds the
    # pnpm store path now that no npmrc declares it.
  };
}
