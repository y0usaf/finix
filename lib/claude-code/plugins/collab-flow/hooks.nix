# Hooks configuration for collab-flow plugin
# Plain text stdout with exit 0 adds context to UserPromptSubmit/SessionStart
{
  config = {
    UserPromptSubmit = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/askuser-reminder.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "askuser-reminder.sh" = ''
            #!/usr/bin/env bash
            cat <<'EOF'
      <system-reminder>
      MANDATORY: You MUST use AskUserQuestion EVERY response. No exceptions.

      Example:

      <invoke name="AskUserQuestion">
      <parameter name="questions">[{"question": "What approach do you prefer?", "header": "Architecture", "options": [{"label": "Option A", "description": "Why choose A"}, {"label": "Option B", "description": "Why choose B"}], "multiSelect": false}]</parameter>
      </invoke>

      Rules:
      - Ask at least ONE clarification or confirmation
      - Even if requirements seem clear, verify assumptions
      - NEVER proceed without asking first
      - Collaboration over autonomy
      </system-reminder>
      EOF
    '';
  };
}
