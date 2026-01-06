# Hooks configuration for codex-mcp plugin
# Plain text stdout with exit 0 adds context to UserPromptSubmit/SessionStart
{
  config = {
    SessionStart = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/codex-reminder.sh";
          }
        ];
      }
    ];
    UserPromptSubmit = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/codex-reminder.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "codex-reminder.sh" = ''
            #!/usr/bin/env bash
            cat <<'EOF'
      <system-reminder>
      Use Codex MCP when seeking reviews or second opinions.
      </system-reminder>
      EOF
    '';
  };
}
