{
  config,
  lib,
  ...
}: let
  toKDL = import ../../../../lib/generators/toKDL.nix {inherit lib;};

  neonTheme = {
    themes.neon = {
      text_unselected = {
        base = [180 180 180]; # #b4b4b4
        background = [15 15 15]; # #0f0f0f
        emphasis_0 = [255 100 0]; # orange
        emphasis_1 = [0 255 150]; # cyan
        emphasis_2 = [0 255 100]; # green
        emphasis_3 = [255 0 100]; # red
      };
      text_selected = {
        base = [180 180 180];
        background = [31 31 31]; # darker grey
        emphasis_0 = [255 100 0];
        emphasis_1 = [0 255 150];
        emphasis_2 = [0 255 100];
        emphasis_3 = [255 0 100];
      };
      ribbon_unselected = {
        base = [0 0 0]; # black text on bright bg
        background = [0 255 100]; # neon green
        emphasis_0 = [255 0 100];
        emphasis_1 = [0 200 255];
        emphasis_2 = [200 0 255];
        emphasis_3 = [255 100 0];
      };
      ribbon_selected = {
        base = [0 0 0];
        background = [0 255 150]; # neon cyan for active
        emphasis_0 = [255 0 100];
        emphasis_1 = [0 200 255];
        emphasis_2 = [200 0 255];
        emphasis_3 = [255 100 0];
      };
      table_title = {
        base = [0 255 100];
        background = [15 15 15];
        emphasis_0 = [255 100 0];
        emphasis_1 = [0 255 150];
        emphasis_2 = [200 0 255];
        emphasis_3 = [0 200 255];
      };
      table_cell_unselected = {
        base = [180 180 180];
        background = [15 15 15];
        emphasis_0 = [255 100 0];
        emphasis_1 = [0 255 150];
        emphasis_2 = [0 255 100];
        emphasis_3 = [255 0 100];
      };
      table_cell_selected = {
        base = [180 180 180];
        background = [31 31 31];
        emphasis_0 = [255 100 0];
        emphasis_1 = [0 255 150];
        emphasis_2 = [0 255 100];
        emphasis_3 = [255 0 100];
      };
      list_unselected = {
        base = [180 180 180];
        background = [15 15 15];
        emphasis_0 = [255 100 0];
        emphasis_1 = [0 255 150];
        emphasis_2 = [0 255 100];
        emphasis_3 = [255 0 100];
      };
      list_selected = {
        base = [180 180 180];
        background = [31 31 31];
        emphasis_0 = [255 100 0];
        emphasis_1 = [0 255 150];
        emphasis_2 = [0 255 100];
        emphasis_3 = [255 0 100];
      };
      frame_selected = {
        base = [0 255 100]; # neon green border
        background = [15 15 15];
        emphasis_0 = [255 100 0];
        emphasis_1 = [0 255 150];
        emphasis_2 = [200 0 255];
        emphasis_3 = [0 200 255];
      };
      frame_highlight = {
        base = [0 200 255]; # neon blue highlight
        background = [15 15 15];
        emphasis_0 = [255 100 0];
        emphasis_1 = [200 0 255];
        emphasis_2 = [0 255 100];
        emphasis_3 = [255 0 100];
      };
      exit_code_success = {
        base = [0 255 100];
        background = [15 15 15];
        emphasis_0 = [0 255 150];
        emphasis_1 = [0 200 255];
        emphasis_2 = [200 0 255];
        emphasis_3 = [255 100 0];
      };
      exit_code_error = {
        base = [255 0 100];
        background = [15 15 15];
        emphasis_0 = [255 100 0];
        emphasis_1 = [0 0 0];
        emphasis_2 = [0 0 0];
        emphasis_3 = [0 0 0];
      };
    };
  };

  uiConfig = {
    ui.pane_frames = {
      rounded_corners = false;
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
