{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.shell.zellij.enable {
    usr.files.".config/zellij/config.kdl" = {
      clobber = false;
      text =
        "\n// Neon theme configuration\n"
        + lib.generators.toKDL {} {
          themes.neon = {
            text_unselected = {
              base = [180 180 180]; # #b4b4b4
              background = [60 60 60]; # grey bg
              emphasis_0 = [255 100 0]; # orange
              emphasis_1 = [0 255 150]; # cyan
              emphasis_2 = [0 255 100]; # green
              emphasis_3 = [255 0 100]; # red
            };
            text_selected = {
              base = [0 255 150]; # neon cyan text
              background = [80 80 80]; # lighter grey for selected
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [0 255 100];
              emphasis_3 = [255 0 100];
            };
            ribbon_unselected = {
              base = [0 255 100]; # neon green text
              background = [60 60 60]; # grey bg
              emphasis_0 = [255 0 100];
              emphasis_1 = [0 200 255];
              emphasis_2 = [200 0 255];
              emphasis_3 = [255 100 0];
            };
            ribbon_selected = {
              base = [0 255 150]; # neon cyan text
              background = [80 80 80]; # lighter grey for selected
              emphasis_0 = [255 0 100];
              emphasis_1 = [0 200 255];
              emphasis_2 = [200 0 255];
              emphasis_3 = [255 100 0];
            };
            table_title = {
              base = [0 255 100]; # neon green text
              background = [60 60 60]; # grey bg
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [200 0 255];
              emphasis_3 = [0 200 255];
            };
            table_cell_unselected = {
              base = [180 180 180];
              background = [60 60 60]; # grey bg
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [0 255 100];
              emphasis_3 = [255 0 100];
            };
            table_cell_selected = {
              base = [0 255 150]; # neon cyan text
              background = [80 80 80]; # lighter grey for selected
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [0 255 100];
              emphasis_3 = [255 0 100];
            };
            list_unselected = {
              base = [180 180 180];
              background = [60 60 60]; # grey bg
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [0 255 100];
              emphasis_3 = [255 0 100];
            };
            list_selected = {
              base = [0 255 150]; # neon cyan text
              background = [80 80 80]; # lighter grey for selected
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [0 255 100];
              emphasis_3 = [255 0 100];
            };
            frame_selected = {
              base = [0 255 100]; # neon green border
              background = [60 60 60]; # grey bg
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [200 0 255];
              emphasis_3 = [0 200 255];
            };
            frame_highlight = {
              base = [0 200 255]; # neon blue highlight
              background = [60 60 60]; # grey bg
              emphasis_0 = [255 100 0];
              emphasis_1 = [200 0 255];
              emphasis_2 = [0 255 100];
              emphasis_3 = [255 0 100];
            };
            exit_code_success = {
              base = [0 255 100]; # neon green text
              background = [60 60 60]; # grey bg
              emphasis_0 = [0 255 150];
              emphasis_1 = [0 200 255];
              emphasis_2 = [200 0 255];
              emphasis_3 = [255 100 0];
            };
            exit_code_error = {
              base = [255 0 100]; # neon red text
              background = [60 60 60]; # grey bg
              emphasis_0 = [255 100 0];
              emphasis_1 = [180 180 180];
              emphasis_2 = [100 100 100];
              emphasis_3 = [50 50 50];
            };
          };
        }
        + "\n"
        + lib.generators.toKDL {} {
          ui.pane_frames = {
            rounded_corners = false;
            hide_session_name = false;
          };
        }
        + "\n\ntheme \"neon\"\n";
    };
  };
}
