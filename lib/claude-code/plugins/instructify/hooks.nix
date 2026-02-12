# Hooks configuration for instructify plugin
# Registers the dispatch script for all 12 hook event types
let
  events = [
    "SessionStart"
    "UserPromptSubmit"
    "PreToolUse"
    "PermissionRequest"
    "PostToolUse"
    "PostToolUseFailure"
    "Notification"
    "SubagentStart"
    "SubagentStop"
    "Stop"
    "PreCompact"
    "SessionEnd"
  ];
in {
  config = builtins.listToAttrs (map (event: {
      name = event;
      value = [
        {
          matcher = "";
          hooks = [
            {
              type = "command";
              command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/instructify-dispatch.sh";
            }
          ];
        }
      ];
    })
    events);

  scripts = {
    "instructify-dispatch.sh" = builtins.readFile ./instructify-dispatch.sh;
  };
}
