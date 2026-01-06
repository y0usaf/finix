# Hooks configuration for parallelization-instruct plugin
# Plain text stdout with exit 0 adds context to UserPromptSubmit/SessionStart
{
  config = {
    UserPromptSubmit = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/parallel-reminder.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "parallel-reminder.sh" = ''
            #!/usr/bin/env bash
            cat <<'EOF'
      <system-reminder>
      MANDATORY: Parallelize ALL independent tool calls. Single message, multiple calls.

      Example (parallel):

      <invoke name="Read">
      <parameter name="file_path">/path/to/file1</parameter>
      </invoke>

      <invoke name="Read">
      <parameter name="file_path">/path/to/file2</parameter>
      </invoke>

      <invoke name="Bash">
      <parameter name="command">git status</parameter>
      <parameter name="description">Check repo status</parameter>
      </invoke>

      If B does not need output from A → PARALLEL in same message.
      </system-reminder>
      EOF
    '';
  };
}
