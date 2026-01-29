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
      echo '<system-reminder>MANDATORY: Use AskUserQuestion before proceeding.</system-reminder>'
    '';
  };
}
