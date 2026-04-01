{
  config,
  lib,
  pkgs,
  ...
}: let
  claudeCodeConfig = import ./data/claude-code-lib.nix;
  inherit (config) user;
  userDev = user.dev;
  claudeCodeCfg = userDev.claude-code;
  ccSettings = claudeCodeConfig.settings;
  ghEnabled = lib.attrByPath ["tools" "gh" "enable"] false user;
in {
  config = lib.mkIf claudeCodeCfg.enable {
    bayt.users."${config.user.name}".files =
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
          source = ./assets/tuturu.ogg;
          clobber = true;
        };

        ".claude/on-agent-complete.wav" = {
          source = ./assets/tuturu.ogg;
          clobber = true;
        };

        ".claude/CLAUDE.md" = {
          text = claudeCodeConfig.instructions;
          clobber = true;
        };
      };

    # settings.json via patchix — mutable so Claude Code can toggle plugins
    patchix = {
      enable = true;
      users."${user.name}".patches.".claude/settings.json" = {
        format = "json";
        clobber = false;
        value = {
          inherit (ccSettings) includeCoAuthoredBy permissions;
          statusLine = {
            type = "command";
            command = "${import ./data/statusline.nix {inherit pkgs;}}/bin/statusline";
          };
          inherit (claudeCodeCfg) model;
          env =
            ccSettings.env
            // {
              CLAUDE_CODE_SUBAGENT_MODEL = claudeCodeCfg.subagentModel;
            };
          enabledPlugins = let
            inherit (claudeCodeCfg) skills;
          in {
            "agent-slack@y0usaf-marketplace" = userDev.agent-slack.enable && skills.agent-slack.enable;
            "audio-notify@y0usaf-marketplace" = true;
            "codex-mcp@y0usaf-marketplace" = false;
            "collab-flow@y0usaf-marketplace" = false;
            "gh@y0usaf-marketplace" = ghEnabled && skills.gh.enable;
            "instructify@y0usaf-marketplace" = true;
            "linear-cli@y0usaf-marketplace" = skills.linear-cli.enable;
            "teams-instruct@y0usaf-marketplace" = false;
            "todowrite-instruct@y0usaf-marketplace" = false;
            "tool-tracker@y0usaf-marketplace" = false;
            "ralph-loop@claude-plugins-official" = false;
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
                path = "${user.homeDirectory}/.config/claude";
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
  };
}
