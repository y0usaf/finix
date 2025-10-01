_: {
  claudeSettings = {
    includeCoAuthoredBy = false;
    outputStyle = "explanatory";
    model = "claude-sonnet-4-5-20250929";
    env = {
      MAX_THINKING_TOKENS = "31999";
    };
    statusLine = {
      type = "command";
      command = "npx ccusage statusline";
    };
  };
}
