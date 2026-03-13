{
  config,
  lib,
  pkgs,
  ...
}: let
  claudeCodeConfig = import ../../../../lib/claude-code;
  # Build the marketplace with all plugins
  # Settings without hooks (hooks come from plugin now)
  statuslineScript = import ../../../../lib/claude-code/statusline.nix {inherit pkgs;};
in {
  imports = [
    ./claude-code.nix
    ./tweakcc.nix
  ];

  config = lib.mkIf config.user.dev.claude-code.enable {
    usr.files =
      # Marketplace files (plugins, commands, hooks, etc.)
      ((claudeCodeConfig.marketplace {inherit lib;}).build {
        name = "y0usaf-marketplace";
        owner = {
          name = "y0usaf";
          email = "";
        };
        inherit (claudeCodeConfig) plugins;
        basePath = ".config/claude"; # ~/.config/claude/
        description = "Personal Claude Code plugin marketplace";
        version = "1.0.0";
      })
      // {
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

    # settings.json via patchix — mutable so Claude Code can toggle plugins
    patchix.enable = true;
    patchix.users."${config.user.name}".patches.".claude/settings.json" = {
      format = "json";
      clobber = false;
      value = {
        inherit (claudeCodeConfig.settings) includeCoAuthoredBy permissions;
        statusLine = {
          type = "command";
          command = "${statuslineScript}/bin/statusline";
        };
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
          "codex-mcp@ai-eng-plugins" = false;
          "collab-flow@ai-eng-plugins" = false;
          "skills-framework@ai-eng-plugins" = true;
          "the-chopper@ai-eng-plugins" = true;
          "skill-eval-hook@ai-eng-plugins" = false;
          "skillify@ai-eng-plugins" = true;
        };
        extraKnownMarketplaces = {
          "y0usaf-marketplace" = {
            source = {
              source = "directory";
              path = "${config.user.homeDirectory}/.config/claude";
            };
          };
          "ai-eng-plugins" = {
            source = {
              source = "github";
              owner = "Cook-Unity";
              repo = "ai-eng-plugins";
            };
          };
        };
      };
    };
  };
}
