{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages =
    [
      pkgs.tailscale
      pkgs.syncthing
      pkgs.podman
      pkgs.gvfs
      pkgs.rsync
      pkgs.bind
      pkgs.btrbk
      pkgs.fuse3
      pkgs.shared-mime-info
      pkgs.strace
    ]
    ++ lib.optionals config.user.gaming.steam.enable [
      (
        if config.user.gaming.proton.enable
        then
          pkgs.steam.override {
            extraEnv.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-ge-bin.steamcompattool}";
          }
        else pkgs.steam
      )
      pkgs.steam-run
    ]
    ++ lib.optional config.user.dev.pi.enable
    flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".pi-full;
}
