{lib, ...}: {
  options.user.services.udiskie = {
    enable = lib.mkEnableOption "udiskie USB auto-mounting";
  };
}