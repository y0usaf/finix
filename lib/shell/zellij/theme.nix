_: {
  themes.sunset = {
    text_unselected = {
      base = [160 128 144]; # #a08090 muted mauve
      background = [26 16 37]; # #1a1025 dark purple
      emphasis_0 = [255 107 53]; # #ff6b35 sunset orange
      emphasis_1 = [255 179 71]; # #ffb347 golden
      emphasis_2 = [255 51 102]; # #ff3366 hot pink
      emphasis_3 = [255 215 0]; # #ffd700 gold
    };
    text_selected = {
      base = [255 107 53]; # #ff6b35 sunset orange
      background = [40 25 55]; # #281937 lighter purple
      emphasis_0 = [255 51 153]; # #ff3399 pink
      emphasis_1 = [255 204 0]; # #ffcc00 yellow
      emphasis_2 = [255 0 102]; # #ff0066 magenta
      emphasis_3 = [255 127 80]; # #ff7f50 coral
    };
    ribbon_unselected = {
      base = [255 179 71]; # golden
      background = [26 16 37]; # dark purple
      emphasis_0 = [255 51 102]; # hot pink
      emphasis_1 = [255 107 53]; # sunset orange
      emphasis_2 = [255 0 153]; # #ff0099 magenta
      emphasis_3 = [255 215 0]; # gold
    };
    ribbon_selected = {
      base = [255 107 53]; # sunset orange
      background = [40 25 55]; # lighter purple
      emphasis_0 = [255 51 153]; # pink
      emphasis_1 = [255 204 0]; # yellow
      emphasis_2 = [255 85 119]; # #ff5577 salmon
      emphasis_3 = [255 149 0]; # #ff9500 amber
    };
    table_title = {
      base = [255 107 53]; # sunset orange
      background = [26 16 37]; # dark purple
      emphasis_0 = [255 179 71]; # golden
      emphasis_1 = [255 51 102]; # hot pink
      emphasis_2 = [255 0 153]; # magenta
      emphasis_3 = [255 215 0]; # gold
    };
    table_cell_unselected = {
      base = [160 128 144]; # muted mauve
      background = [26 16 37]; # dark purple
      emphasis_0 = [255 107 53]; # sunset orange
      emphasis_1 = [255 179 71]; # golden
      emphasis_2 = [255 51 102]; # hot pink
      emphasis_3 = [255 127 80]; # coral
    };
    table_cell_selected = {
      base = [255 107 53]; # sunset orange
      background = [40 25 55]; # lighter purple
      emphasis_0 = [255 51 153]; # pink
      emphasis_1 = [255 204 0]; # yellow
      emphasis_2 = [255 0 102]; # magenta
      emphasis_3 = [255 149 0]; # amber
    };
    list_unselected = {
      base = [160 128 144]; # muted mauve
      background = [26 16 37]; # dark purple
      emphasis_0 = [255 107 53]; # sunset orange
      emphasis_1 = [255 179 71]; # golden
      emphasis_2 = [255 51 102]; # hot pink
      emphasis_3 = [255 215 0]; # gold
    };
    list_selected = {
      base = [255 107 53]; # sunset orange
      background = [40 25 55]; # lighter purple
      emphasis_0 = [255 51 153]; # pink
      emphasis_1 = [255 204 0]; # yellow
      emphasis_2 = [255 0 153]; # magenta
      emphasis_3 = [255 127 80]; # coral
    };
    frame_selected = {
      base = [255 107 53]; # sunset orange border
      background = [26 16 37]; # dark purple
      emphasis_0 = [255 51 102]; # hot pink
      emphasis_1 = [255 179 71]; # golden
      emphasis_2 = [255 0 153]; # magenta
      emphasis_3 = [255 215 0]; # gold
    };
    frame_highlight = {
      base = [255 51 102]; # hot pink highlight
      background = [26 16 37]; # dark purple
      emphasis_0 = [255 107 53]; # sunset orange
      emphasis_1 = [255 0 153]; # magenta
      emphasis_2 = [255 179 71]; # golden
      emphasis_3 = [255 127 80]; # coral
    };
    # CRITICAL: Without this, unfocused borders default to white!
    frame_unselected = {
      base = [80 50 90]; # dim magenta (NOT white - matches theme)
      background = [26 16 37]; # dark purple
      emphasis_0 = [160 128 144]; # muted mauve
      emphasis_1 = [255 107 53]; # sunset orange
      emphasis_2 = [255 51 102]; # hot pink
      emphasis_3 = [255 215 0]; # gold
    };
    exit_code_success = {
      base = [255 179 71]; # golden
      background = [26 16 37]; # dark purple
      emphasis_0 = [255 107 53]; # sunset orange
      emphasis_1 = [255 215 0]; # gold
      emphasis_2 = [255 51 102]; # hot pink
      emphasis_3 = [255 204 0]; # yellow
    };
    exit_code_error = {
      base = [255 51 102]; # hot pink
      background = [26 16 37]; # dark purple
      emphasis_0 = [255 107 53]; # sunset orange
      emphasis_1 = [160 128 144]; # muted mauve
      emphasis_2 = [80 50 70]; # dim purple
      emphasis_3 = [40 25 55]; # darker
    };
  };
  ui.pane_frames = {
    rounded_corners = false;
    hide_session_name = false;
  };
  theme = "sunset";
}
