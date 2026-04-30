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
    teams-instruct = {
      name = "teams-instruct";
      version = "1.0.0";
      description = "Reminders to always use agent teams for task parallelization";
      author = {
        name = "y0usaf";
      };
      hooks = {
        config = {
          UserPromptSubmit = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = ''
                    cat <<'EOF'
                    <system-reminder>
                    MANDATORY: Use Agent Teams for ALL tasks. Never work alone when teammates can parallelize the effort.

                    Workflow:
                    1. TeamCreate -> create a team
                    2. TaskCreate -> break work into subtasks
                    3. Task tool (with team_name and name params) -> spawn teammates
                    4. TaskUpdate (with owner param) -> assign tasks to teammates
                    5. SendMessage type: "shutdown_request" -> when all work is complete
                    6. TeamDelete -> clean up

                    Always break work into parallel subtasks and delegate to teammates.
                    </system-reminder>
                    EOF
                  '';
                }
              ];
            }
          ];
        };
      };
    };
  };
}
