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
  options.user.ui.monstar = {
    enable = lib.mkEnableOption "monstar terminal emulator";
  };
  config = lib.mkIf userUi.monstar.enable {
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
  };
}
