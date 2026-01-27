# Hooks configuration for linear-mcp plugin
# Plain text stdout with exit 0 adds context to SessionStart
{
  config = {
    SessionStart = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/linear-reminder.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "linear-reminder.sh" = ''
      #!/usr/bin/env bash
      if [ -z "$LINEAR_API_KEY" ] && [ -z "$CLAUDE_LINEAR_API_KEY" ]; then
        cat <<'EOF'
      <system-reminder>
      Linear MCP is available. To use it, set your Linear API key:
        export LINEAR_API_KEY="lin_xxx..."
      Get your API key from: https://linear.app/settings/api
      </system-reminder>
      EOF
      else
        exit 0
      fi
    '';
  };
}
