{pkgs, ...}: {
  environment.systemPackages = [pkgs.btop];
  user.files.".config/btop/btop.conf".text = ''
    color_theme = "TTY"
    theme_background = False
  '';
}
