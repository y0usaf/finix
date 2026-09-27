{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.btop];
  manzil.users."${config.user.name}".files.".config/btop/btop.conf" = {
    text = ''
      color_theme = "TTY"
      theme_background = False
    '';
  };
}
