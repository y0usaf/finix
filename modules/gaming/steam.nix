{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".SteamCloud"
    ".steam"
  ];
  environment.systemPackages = [
    (
      if config.user.gaming.proton.enable
      then
        pkgs.steam.override {
          extraEnv.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-ge-bin.steamcompattool}";
        }
      else pkgs.steam
    )
    pkgs.steam-run
  ];
}
