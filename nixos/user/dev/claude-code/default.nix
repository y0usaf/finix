{
  config,
  lib,
  ...
}: let
  claudeCodeConfig = import ../../../../lib/claude-code;

  # Build the marketplace with all plugins
  marketplace = (claudeCodeConfig.marketplace {inherit lib;}).build {
    name = "y0usaf-marketplace";
    owner = {
      name = "y0usaf";
      email = "";
    };
    inherit (claudeCodeConfig) plugins;
    basePath = ".config/claude"; # ~/.config/claude/
    description = "Personal Claude Code plugin marketplace";
    version = "1.0.0";
  };

  # Settings without hooks (hooks come from plugin now)
  settingsWithoutHooks = {
    inherit (claudeCodeConfig.settings) includeCoAuthoredBy statusLine permissions;
    inherit (config.user.dev.claude-code) model;
    env =
      claudeCodeConfig.settings.env
      // {
        CLAUDE_CODE_SUBAGENT_MODEL = config.user.dev.claude-code.subagentModel;
      };
    enabledPlugins = {
      "agent-slack@y0usaf-marketplace" = config.user.dev.agent-slack.enable && config.user.dev.claude-code.skills.agent-slack.enable;
      "audio-notify@y0usaf-marketplace" = true;
      "codex-mcp@y0usaf-marketplace" = false;
      "collab-flow@y0usaf-marketplace" = false;
      "gh@y0usaf-marketplace" = config.user.tools.gh.enable && config.user.dev.claude-code.skills.gh.enable;
      "instructify@y0usaf-marketplace" = true;
      "linear-cli@y0usaf-marketplace" = config.user.dev.claude-code.skills.linear-cli.enable;
      "teams-instruct@y0usaf-marketplace" = false;
      "todowrite-instruct@y0usaf-marketplace" = false;
      "tool-tracker@y0usaf-marketplace" = false;
      "ralph-loop@claude-plugins-official" = false;
      "code-simplifier@claude-plugins-official" = true;
      # CU-Claude-Plugins
      "codex-mcp@CU-Claude-Plugins" = false;
      "collab-flow@CU-Claude-Plugins" = false;
      "skills-framework@CU-Claude-Plugins" = true;
      "the-chopper@CU-Claude-Plugins" = true;
      "skill-eval-hook@CU-Claude-Plugins" = false;
      "skillify@CU-Claude-Plugins" = true;
    };
    extraKnownMarketplaces = {
      "y0usaf-marketplace" = {
        source = {
          source = "directory";
          path = "${config.user.homeDirectory}/.config/claude";
        };
      };
      "CU-Claude-Plugins" = {
        source = {
          source = "github";
          owner = "Cook-Unity";
          repo = "CU-Claude-Plugins";
        };
      };
    };
  };
in {
  imports = [
    ./claude-code.nix
    ./tweakcc.nix
  ];

  config = lib.mkIf config.user.dev.claude-code.enable {
    usr.files =
      # Marketplace files (plugins, commands, hooks, etc.)
      marketplace
      # Base Claude settings (model, env, etc. - NO hooks)
      // {
        ".claude/settings.json" = {
          text = builtins.toJSON settingsWithoutHooks;
          clobber = true;
        };

        # Sound files for notifications
        ".claude/on-agent-need-attention.wav" = {
          source = ../../../../lib/claude-code/tuturu.ogg;
          clobber = true;
        };

        ".claude/on-agent-complete.wav" = {
          source = ../../../../lib/claude-code/tuturu.ogg;
          clobber = true;
        };

        ".claude/CLAUDE.md" = {
          text = claudeCodeConfig.instructions;
          clobber = true;
        };
      };
  };
}
