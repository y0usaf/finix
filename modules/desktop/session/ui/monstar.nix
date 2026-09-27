{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) user;
  userUi = user.ui;
  computedFontSize = toString user.appearance.termFontSize;
in {
  user.defaults.terminal = lib.mkDefault "monstar";

  environment.systemPackages = [
    pkgs.monstar
  ];

  manzil.users."${config.user.name}".files.".config/monstar/config" = {
    text = ''
      font-size = ${computedFontSize}
      background-opacity = 0.82
      line-height = ${userUi.foot.lineHeight}
      theme = ${config.user.homeDirectory}${lib.removePrefix "~" user.appearance.wallust.targets.monstar-colors.target}
    '';
  };
}
