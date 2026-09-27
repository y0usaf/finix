{
  config,
  lib,
  pkgs,
  ...
}: {
  user.defaults.terminal = lib.mkDefault "monstar";

  environment.systemPackages = [
    pkgs.monstar
  ];

  manzil.users."${config.user.name}".files.".config/monstar/config" = {
    text = ''
      font-size = ${toString config.user.appearance.termFontSize}
      background-opacity = 0.82
      line-height = ${config.user.ui.foot.lineHeight}
      theme = ${config.user.homeDirectory}/.cache/wallust/colors_monstar
    '';
  };
}
