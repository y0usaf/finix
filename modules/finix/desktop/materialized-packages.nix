{
  config,
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    pkgs.tailscale
    pkgs.syncthing
    pkgs.podman
    pkgs.gvfs
    pkgs.rsync
    pkgs.bind
    pkgs.btrbk
    pkgs.fuse3
    pkgs.strace
    (
      if config.user.gaming.proton.enable
      then
        pkgs.steam.override {
          extraEnv.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-ge-bin.steamcompattool}";
        }
      else pkgs.steam
    )
    pkgs.steam-run
    flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".pi-full
  ];
}
