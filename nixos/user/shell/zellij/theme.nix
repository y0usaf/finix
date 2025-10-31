{
  config,
  lib,
  genLib,
  ...
}: {
  config = lib.mkIf config.user.shell.zellij.enable {
    usr.files.".config/zellij/config.kdl" = {
      clobber = false;
      text =
        "\n// Neon theme configuration\n"
        + genLib.toKDL {
          themes.neon = {
            text_unselected = {
              base = [180 180 180];
              background = [60 60 60];
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [0 255 100];
              emphasis_3 = [255 0 100];
            };
            text_selected = {
              base = [0 255 150];
              background = [80 80 80];
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [0 255 100];
              emphasis_3 = [255 0 100];
            };
            ribbon_unselected = {
              base = [0 255 100];
              background = [60 60 60];
              emphasis_0 = [255 0 100];
              emphasis_1 = [0 200 255];
              emphasis_2 = [200 0 255];
              emphasis_3 = [255 100 0];
            };
            ribbon_selected = {
              base = [0 255 150];
              background = [80 80 80];
              emphasis_0 = [255 0 100];
              emphasis_1 = [0 200 255];
              emphasis_2 = [200 0 255];
              emphasis_3 = [255 100 0];
            };
            table_title = {
              base = [0 255 100];
              background = [60 60 60];
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [200 0 255];
              emphasis_3 = [0 200 255];
            };
            table_cell_unselected = {
              base = [180 180 180];
              background = [60 60 60];
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [0 255 100];
              emphasis_3 = [255 0 100];
            };
            table_cell_selected = {
              base = [0 255 150];
              background = [80 80 80];
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [0 255 100];
              emphasis_3 = [255 0 100];
            };
            list_unselected = {
              base = [180 180 180];
              background = [60 60 60];
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [0 255 100];
              emphasis_3 = [255 0 100];
            };
            list_selected = {
              base = [0 255 150];
              background = [80 80 80];
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [0 255 100];
              emphasis_3 = [255 0 100];
            };
            frame_selected = {
              base = [0 255 100];
              background = [60 60 60];
              emphasis_0 = [255 100 0];
              emphasis_1 = [0 255 150];
              emphasis_2 = [200 0 255];
              emphasis_3 = [0 200 255];
            };
            frame_highlight = {
              base = [0 200 255];
              background = [60 60 60];
              emphasis_0 = [255 100 0];
              emphasis_1 = [200 0 255];
              emphasis_2 = [0 255 100];
              emphasis_3 = [255 0 100];
            };
            exit_code_success = {
              base = [0 255 100];
              background = [60 60 60];
              emphasis_0 = [0 255 150];
              emphasis_1 = [0 200 255];
              emphasis_2 = [200 0 255];
              emphasis_3 = [255 100 0];
            };
            exit_code_error = {
              base = [255 0 100];
              background = [60 60 60];
              emphasis_0 = [255 100 0];
              emphasis_1 = [180 180 180];
              emphasis_2 = [100 100 100];
              emphasis_3 = [50 50 50];
            };
          };
        }
        + "\n"
        + genLib.toKDL {
          ui.pane_frames = {
            rounded_corners = false;
            hide_session_name = false;
          };
        }
        + "\n\ntheme \"neon\"\n";
    };
  };
}
