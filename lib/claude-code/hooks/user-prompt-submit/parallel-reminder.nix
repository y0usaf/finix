''
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
''
