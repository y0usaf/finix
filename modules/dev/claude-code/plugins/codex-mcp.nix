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
    codex-mcp = {
      name = "codex-mcp";
      version = "1.0.0";
      description = "OpenAI Codex MCP server for second opinions and reasoning";
      author = {
        name = "y0usaf";
      };
      hooks = {
        config = {
          SessionStart = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = codexReminderCommand;
                }
              ];
            }
          ];
          UserPromptSubmit = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = codexReminderCommand;
                }
              ];
            }
          ];
        };
      };
      mcpServers = {
        codex = {
          command = "bunx";
          args = [
            "--bun"
            "@openai/codex"
            "mcp-server"
            "-c"
            "model=gpt-5.2-codex"
            "-c"
            "model_reasoning_effort=high"
          ];
        };
      };
    };
  };
}
