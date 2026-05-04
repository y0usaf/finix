{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.btop = {
    enable = lib.mkEnableOption "btop system monitor";
  };
  config = lib.mkIf config.user.programs.btop.enable {
    environment.systemPackages = [pkgs.btop];
    manzil.users."${config.user.name}".files.".config/btop/btop.conf" = {
      text = ''
        color_theme = "TTY"
        theme_background = False
      '';
    };
  };
}
