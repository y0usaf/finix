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
      echo '<system-reminder>MANDATORY: Use TaskCreate before proceeding.</system-reminder>'
    '';
  };
}
