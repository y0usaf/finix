{
  includeCoAuthoredBy = false;
  model = "claude-opus-4-5";
  env = {
    MAX_THINKING_TOKENS = "0";
    BASH_DEFAULT_TIMEOUT_MS = "900000";
    DISABLE_TELEMETRY = "1";
    CLAUDE_CODE_SUBAGENT_MODEL = "claude-haiku-4-5";
  };
  statusLine = {
    type = "command";
    command = "bunx ccusage statusline";
  };
}
