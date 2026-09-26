{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) user;
  userUi = user.ui;
  computedFontSize = toString user.appearance.termFontSize;
  monstarColorsTarget = lib.attrByPath ["user" "appearance" "wallust" "targets" "monstar-colors" "target"] null config;
  monstarThemePath =
    lib.optionalString (monstarColorsTarget != null)
    "${config.user.homeDirectory}${lib.removePrefix "~" monstarColorsTarget}";
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
        ${lib.optionalString (monstarColorsTarget != null) "theme = ${monstarThemePath}"}
      '';
    };
  };
}
