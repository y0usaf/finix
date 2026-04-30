{...}: let
  aiSkills = {
    agent-slack = import ../../skills/agent-slack.nix {moduleMode = false;};
    gh = import ../../skills/gh.nix {moduleMode = false;};
    linear-cli = import ../../skills/linear-cli.nix {moduleMode = false;};
  };

  codexReminderCommand = ''    printf '%s\n' '<system-reminder>
    Use Codex MCP when seeking reviews or second opinions.
    </system-reminder>''''';
in {
  config.user.dev.claude-code.plugins = {
    instructify = {
      name = "instructify";
      version = "1.1.0";
      description = "Config-driven hook instruction injector - maps hook events to system reminders";
      author = {
        name = "y0usaf";
      };
      hooks = {
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
          [
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
          ]);
        scripts = {
          "instructify-dispatch.sh" = ''
            #!/usr/bin/env bash
            # instructify-dispatch.sh — Config-driven hook instruction injector
            # Reads instructions.json and injects matching system reminders for any hook event.

            set -euo pipefail

            # Read all of stdin
            input=$(cat)

            # Check for jq
            if ! command -v jq &>/dev/null; then
              echo '{"error":"jq is required but not installed"}' >&2
              exit 1
            fi

            # Extract hook event name
            event=$(echo "$input" | jq -r '.hook_event_name // empty')
            if [[ -z "$event" ]]; then
              exit 0
            fi

            # Resolve instructions.json path
            plugin_root="''${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "''${BASH_SOURCE[0]}")/.." && pwd)}"
            config="$plugin_root/instructions.json"

            if [[ ! -f "$config" ]]; then
              exit 0
            fi

            # Extract the filterable value from the event data depending on event type
            get_filter_value() {
              case "$event" in
                SessionStart)
                  echo "$input" | jq -r '.source // empty'
                  ;;
                PreToolUse|PostToolUse|PostToolUseFailure|PermissionRequest)
                  echo "$input" | jq -r '.tool_name // empty'
                  ;;
                Notification)
                  echo "$input" | jq -r '.type // empty'
                  ;;
                SubagentStart|SubagentStop)
                  echo "$input" | jq -r '.agent_type // empty'
                  ;;
                PreCompact)
                  echo "$input" | jq -r '.trigger // empty'
                  ;;
                SessionEnd)
                  echo "$input" | jq -r '.reason // empty'
                  ;;
                *)
                  echo ""
                  ;;
              esac
            }

            filter_value=$(get_filter_value)

            # Collect instructions from all named rules where:
            #   - the current event is in the rule's "events" array
            #   - if the rule has a "matcher", the filter_value matches it
            #   - the rule is not explicitly disabled (enabled != false)
            matched_json=$(jq --arg evt "$event" --arg fv "$filter_value" '
              [
                to_entries[] |
                .value |
                select(type == "object") |
                select((.enabled == false) | not) |
                select(has("events") and (.events | type == "array")) |
                select(.events | index($evt)) |
                if (has("matcher") and (.matcher | type == "string")) then
                  .matcher as $m | select(try ($fv | test($m)) catch false)
                else
                  .
                end |
                select(has("instruction") and (.instruction | type == "string")) |
                .instruction
              ]
            ' "$config" 2>/dev/null) || true

            # Check if any instructions matched
            count=$(echo "$matched_json" | jq 'length' 2>/dev/null) || count=0
            if [[ "$count" -eq 0 || -z "$matched_json" ]]; then
              case "$event" in
                SessionStart|Notification)
                  echo ""
                  ;;
                Stop)
                  exit 0
                  ;;
                *)
                  echo '{"decision":"approve","reason":""}'
                  ;;
              esac
              exit 0
            fi

            # Wrap each matched instruction in system-reminder tags
            wrapped=""
            for i in $(seq 0 $((count - 1))); do
              instruction=$(echo "$matched_json" | jq -r ".[$i]")
              wrapped="''${wrapped}<system-reminder>
            ''${instruction}
            </system-reminder>
            "
            done
            # Trim trailing newline
            wrapped="''${wrapped%$'\n'}"

            # Output the correct JSON format per event type
            case "$event" in
              SessionStart|Notification)
                # Plain text output
                echo "$wrapped"
                ;;
              Stop)
                # Stop events use decision + reason
                reason=$(echo "$wrapped" | jq -Rs .)
                echo "{\"decision\":\"approve\",\"reason\":''${reason}}"
                ;;
              *)
                # All other events use hookSpecificOutput.additionalContext
                context=$(echo "$wrapped" | jq -Rs .)
                echo "{\"decision\":\"approve\",\"reason\":\"\",\"hookSpecificOutput\":{\"hookEventName\":\"''${event}\",\"additionalContext\":''${context}}}"
                ;;
            esac

            exit 0
          '';
        };
      };
      dataFiles = {
        "instructions.json" = builtins.toJSON {
          agentic-terminal-instruct = {
            events = ["UserPromptSubmit"];
            instruction = ''
              MANDATORY: If you are about to tell the user to run a terminal command that you can run agentically, run it yourself instead.
              Only ask the user to run commands when execution is blocked by missing permissions, missing credentials, unavailable local environment, or explicit user preference.'';
          };
        };
      };
    };
  };
}
