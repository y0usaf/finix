# Hooks configuration for todowrite-instruct plugin
# Plain text stdout with exit 0 adds context to UserPromptSubmit/SessionStart
{
  config = {
    UserPromptSubmit = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/todowrite-reminder.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "todowrite-reminder.sh" = ''
            #!/usr/bin/env bash
            cat <<'EOF'
      <system-reminder>
      MANDATORY: You MUST use TodoWrite for EVERY task. No exceptions.

      Example:

      <invoke name="TodoWrite">
      <parameter name="todos">[{"content": "Task description", "status": "pending", "activeForm": "Doing task"}]</parameter>
      </invoke>

      Rules:
      - Create task BEFORE any work
      - Exactly ONE task in_progress at a time
      - Mark completed IMMEDIATELY when done
      - This applies to ALL tasks, not just complex ones
      </system-reminder>
      EOF
    '';
  };
}
