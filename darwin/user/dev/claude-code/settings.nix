{...}: {
  home-manager.users.y0usaf = {
    home.file.".claude/settings.json" = {
      text = builtins.toJSON {
        includeCoAuthoredBy = false;
        outputStyle = "explanatory";
        model = "claude-haiku-4-5-20251001";
        env = {
          MAX_THINKING_TOKENS = "31999";
        };
        statusLine = {
          type = "command";
          command = "bash ~/.claude/statusline.sh";
        };
      };
    };
  };
}
