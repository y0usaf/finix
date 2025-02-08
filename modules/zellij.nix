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
      theme = "custom";
      themes.custom = {
        bg = "#000000";        # black
        fg = "#ffffff";        # white
        red = "#ff0000";       # regular1
        green = "#00ff00";     # regular2
        blue = "#1e90ff";      # regular4
        yellow = "#ffff00";    # regular3
        magenta = "#ff00ff";   # regular5
        orange = "#ff8c00";    # derived from palette
        cyan = "#00ffff";      # regular6
        black = "#000000";     # regular0
        white = "#ffffff";     # regular7
      };
    };
  };
}
