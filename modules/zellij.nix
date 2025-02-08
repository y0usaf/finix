{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # Default layout
      default_layout = "compact";

      # Theme and styling
      theme = "catppuccin";
      themes.catppuccin = {
        bg = "#1e1e2e";
        fg = "#cdd6f4";
        red = "#f38ba8";
        green = "#a6e3a1";
        blue = "#89b4fa";
        yellow = "#f9e2af";
        magenta = "#cba6f7";
        orange = "#fab387";
        cyan = "#89dceb";
        black = "#181825";
        white = "#cdd6f4";
      };

      # UI configuration
      pane_frames = false;
      default_mode = "normal";
      mouse_mode = true;
      scroll_buffer_size = 10000;

      # Key bindings
      keybinds = {
        normal = {
          # Pane management
          "Alt h" = "MoveFocus Left";
          "Alt l" = "MoveFocus Right";
          "Alt j" = "MoveFocus Down";
          "Alt k" = "MoveFocus Up";

          # Tab management
          "Alt n" = "NewTab";
          "Alt [" = "GoToPreviousTab";
          "Alt ]" = "GoToNextTab";

          # Layouts
          "Alt +" = "Resize Increase";
          "Alt -" = "Resize Decrease";
        };
      };
    };
  };
}
