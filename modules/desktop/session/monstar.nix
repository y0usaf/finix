{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    pkgs.monstar
  ];

  manzil.users."${config.user.name}".files.".config/monstar/config" = {
    text = ''
      font-size = ${toString config.user.appearance.termFontSize}
      background-opacity = ${toString config.user.appearance.glass.opacity}
      line-height = ${config.user.ui.foot.lineHeight}
      theme = ${config.user.homeDirectory}/.cache/theme/monstar
    '';
  };
}
