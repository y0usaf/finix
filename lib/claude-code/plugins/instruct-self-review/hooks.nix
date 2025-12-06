# Hooks configuration for instruct-self-review plugin
# JSON output to stdout with exit 0 for proper hook parsing
{
  config = {
    Stop = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/self-review.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "self-review.sh" = ''
      #!/usr/bin/env bash
      # Read stdin to get hook event data
      # Uses "advanced JSON API approach":
      # - Structured JSON output to stdout (not stderr)
      # - Exit code 0 (not non-zero) for proper hook STDOUT capture/parsing
      input=$(cat)

      review_context="<system-reminder>\nCRITICAL REVIEW REQUIRED: Review all file changes that were just made, being critical and following these 2 rules:\n\n1. **The best code is no code** - Question whether each change is necessary. Every line of code is a liability.\n\n2. **The best code is code that can be deleted** - Favor minimal, removable solutions. Avoid adding features or abstractions that might not be used. If code can't be easily deleted later, it's probably too coupled or over-engineered.\n\nAsk yourself:\n- Did I add code that could be removed without breaking functionality?\n- Did I introduce abstractions when a simple solution would suffice?\n- Are there any lines that don't earn their keep?\n- Could the implementation be simpler or more straightforward?\n- Did I add error handling, validation, or features for edge cases that don't exist yet?\n\nRefactor aggressively toward minimalism.\n</system-reminder>"

      echo "{\"decision\":\"approve\",\"reason\":\"\",\"hookSpecificOutput\":{\"additionalContext\":\"$review_context\"}}"
      exit 0
    '';
  };
}
