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
    linear-cli = {
      name = "linear-cli";
      version = "1.0.0";
      description = "Expose the schpet Linear CLI via bunx as an installable skill";
      author = {
        name = "y0usaf";
      };
      skills = {
        inherit (aiSkills) linear-cli;
      };
    };
  };
}
