{
  __keys = ["theme" "copy_on_select" "cursor" "link_target" "contrast" "layout" "font_size" "padding_x" "padding_y" "system_title_bar" "status_bar" "material" "opacity" "blur" "plugins_disabled" "surface_fold" "new_tabs" "agent_placement" "snap_text" "frames_queued" "renderer" "carly" "keybinds"];
  theme = "System";
  copy_on_select = true;
  cursor = {
    programs = true;
    trail = "warp";
  };
  link_target = "Browser";
  contrast = "Always";
  layout = "Rail";
  font_size = 20;
  padding_x = 0;
  padding_y = 0;
  system_title_bar = true;
  status_bar = true;
  material = "Glass";
  opacity = 0;
  blur = 0;
  plugins_disabled = ["chime"];
  surface_fold = true;
  new_tabs = "Home";
  agent_placement = "new_tab";
  snap_text = true;
  # Tern presents on the display's refresh (sync_to_display, on by default), so it already runs at the G9's 240 Hz;
  # its default of 3 frames queued ahead of the display adds latency, so keep one.
  frames_queued = 1;
  renderer = "gpu";
  carly = {
    model = "openai-codex/gpt-6.1-terra:high";
  };
  keybinds = {
    "ctrl+delete" = "close_tab";
    "ctrl+h" = "focus_pane:left";
    "ctrl+j" = "next_tab";
    "ctrl+k" = "previous_tab";
    "ctrl+l" = "focus_pane:right";
    "ctrl+shift+j" = "move_tab_right";
    "ctrl+shift+k" = "move_tab_left";
    "ctrl+tab" = "show_previous_tab";
  };
}
