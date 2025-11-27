''
  #!/usr/bin/env bash
  # UserPromptSubmit hook that auto-activates ensemble skill
  #
  # Ensemble is ALWAYS activated - no evaluation needed.

  cat <<'EOF'
  INSTRUCTION: MANDATORY ENSEMBLE ACTIVATION

  Before proceeding with ANY task, you MUST:
  1. Call `Skill(ensemble)` tool IMMEDIATELY
  2. Follow the ensemble instructions to orchestrate parallel workers
  3. Only then proceed with implementation

  DO NOT skip this step. DO NOT evaluate whether ensemble is needed.
  Ensemble is ALWAYS the right choice for thorough, multi-perspective analysis.
  EOF
''
