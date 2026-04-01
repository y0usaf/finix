{
  includeCoAuthoredBy = false;
  autoMemoryEnabled = false;
  outputStyle = "Explanatory";
  permissions = {
    allow = [
      "Bash(gh api:*)"
      "Bash(bunx @realmikekelly/claude-sneakpeek quick:*)"
      "Bash(echo:*)"
      "Bash(find:*)"
      "Bash(env)"
      "Bash(cat:*)"
    ];
  };
  env = {
    #MAX_THINKING_TOKENS = "56000";
    #BASH_DEFAULT_TIMEOUT_MS = "120000";
    DISABLE_TELEMETRY = "1";
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
  };
}
