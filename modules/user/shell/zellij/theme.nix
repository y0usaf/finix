{
  config,
  lib,
  ...
}: let
  toKDL = import ../../../../lib/generators/toKDL.nix {inherit lib;};

  neonTheme = {
    themes.neon = {
      bg = "#0f0f0f";
      fg = "#b4b4b4";
      red = "#ff0064";
      green = "#00ff64";
      blue = "#00c8ff";
      yellow = "#ff6400";
      magenta = "#c800ff";
      orange = "#ff6400";
      cyan = "#00ff96";
      black = "#000000";
      white = "#ffffff";
    };
  };

  uiConfig = {
    ui.pane_frames = {
      rounded_corners = true;
      hide_session_name = false;
    };
  };
in {
  config = lib.mkIf config.user.shell.zellij.enable {
    usr.files.".config/zellij/config.kdl" = {
      clobber = false;
      text =
        "\n// Neon theme configuration\n"
        + toKDL.toKDL {} neonTheme
        + "\n"
        + toKDL.toKDL {} uiConfig
        + "\n\ntheme \"neon\"\n";
    };
  };
}
