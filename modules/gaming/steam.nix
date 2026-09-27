{
  config,
  lib,
  ...
}: {
  options.user.gaming.steam = {
    enable = lib.mkEnableOption "Steam";
  };

  config = lib.mkIf config.user.gaming.steam.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".SteamCloud"
      ".steam"
    ];
  };
}
