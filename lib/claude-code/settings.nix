{
  includeCoAuthoredBy = false;
  autoMemoryEnabled = false;
  outputStyle = "Explanatory";
  permissions = {
    defaultMode = "acceptEdits";
  };
  env = {
    #MAX_THINKING_TOKENS = "56000";
    #BASH_DEFAULT_TIMEOUT_MS = "120000";
    DISABLE_TELEMETRY = "1";
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
  };
  statusLine = {
    type = "command";
    #command = "bunx ccusage statusline";
    command = "bunx -y @owloops/claude-powerline@latest --style=powerline";
  };
}
