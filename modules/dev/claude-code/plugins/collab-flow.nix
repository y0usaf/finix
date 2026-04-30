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
    collab-flow = {
      name = "collab-flow";
      version = "1.0.0";
      description = "Reminders to use AskUserQuestion for collaboration";
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
                  command = "echo '<system-reminder>MANDATORY: Use AskUserQuestion before proceeding.</system-reminder>'";
                }
              ];
            }
          ];
        };
      };
    };
  };
}
