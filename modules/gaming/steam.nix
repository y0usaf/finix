{
  lib,
  ...
}: {
  options.user.gaming.steam = {
    enable = lib.mkEnableOption "Steam";
  };
}