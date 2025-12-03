# Hooks configuration for prompt-reminders plugin
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
          {
            type = "command";
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/askuser-reminder.sh";
          }
          {
            type = "command";
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/parallel-reminder.sh";
          }
          {
            type = "command";
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/codex-reminder.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "todowrite-reminder.sh" = ''
      #!/usr/bin/env bash
      cat <<'EOF'
      MANDATORY: You MUST use TodoWrite for EVERY task. No exceptions.
      - Create task BEFORE any work
      - Exactly ONE task in_progress at a time
      - Mark completed IMMEDIATELY when done
      - This applies to ALL tasks, not just complex ones
      EOF
    '';

    "askuser-reminder.sh" = ''
      #!/usr/bin/env bash
      cat <<'EOF'
      MANDATORY: You MUST use AskUserQuestion EVERY response. No exceptions.
      - Ask at least ONE clarification or confirmation
      - Even if requirements seem clear, verify assumptions
      - NEVER proceed without asking first
      - Collaboration over autonomy
      EOF
    '';

    "parallel-reminder.sh" = ''
      #!/usr/bin/env bash
      cat <<'EOF'
      <system-reminder>
      MANDATORY: Parallelize ALL independent tool calls. Single message, multiple calls.

      Parallelizable tools:
      - Read: Multiple files → parallel Read calls
      - Glob: Multiple patterns → parallel Glob calls
      - Grep: Multiple searches → parallel Grep calls
      - Task: Multiple agents → parallel Task calls
      - Bash: Independent cmds → parallel Bash calls
      - WebFetch/WebSearch: Multiple URLs/queries → parallel
      - Edit/Write: Independent files → parallel

      Rule: If B doesn't need A's output → PARALLEL in same message
      Anti-pattern: Read file, wait, read another file
      </system-reminder>
      EOF
    '';

    "codex-reminder.sh" = ''
      #!/usr/bin/env bash
      cat <<'EOF'
      CODEX MCP: Use mcp__codex__codex for second opinions and out-of-distribution thinking.
      - Code reviews → get Codex review
      - Design decisions → bounce off Codex
      - Stuck or uncertain → ask Codex
      - Different perspective → Codex has different training
      - Two heads better than one
      EOF
    '';
  };
}
