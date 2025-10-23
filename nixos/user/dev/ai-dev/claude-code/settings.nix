_: {
  claudeSettings = {
    includeCoAuthoredBy = false;
    outputStyle = "explanatory";
    model = "claude-haiku-4-5-20251001";
    env = {
      MAX_THINKING_TOKENS = "31999";
    };
    statusLine = {
      type = "command";
      command = "npx ccusage statusline";
    };
  };
}
