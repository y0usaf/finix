{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) user;

  ghEnabled = lib.attrByPath ["user" "tools" "gh" "enable"] false config;
  agentSlackEnabled = lib.attrByPath ["user" "dev" "agent-slack" "enable"] false config;

  claudeCodeConfig = import ./data/claude-code-lib.nix;
  claudeCodePlugins = claudeCodeConfig.plugins;

  claudeCodeCfg = user.dev.claude-code;

  claudeCodeSkillEnabled = skillName:
    lib.attrByPath ["user" "dev" "claude-code" "skills" skillName "enable"] true config;

  ccSettings = claudeCodeConfig.settings;

  settingsJson = {
    inherit (claudeCodeCfg) model effortLevel extraKnownMarketplaces;
    inherit
      (ccSettings)
      includeCoAuthoredBy
      permissions
      promptSuggestionEnabled
      skipDangerousModePermissionPrompt
      ;
    env =
      ccSettings.env
      // {
        CLAUDE_CODE_SUBAGENT_MODEL = claudeCodeCfg.subagentModel;
      };
    statusLine = {
      type = "command";
      command = "${import ./data/statusline.nix {inherit pkgs;}}/bin/statusline";
    };
    enabledPlugins = lib.filterAttrs (_: enabled: enabled) claudeCodeCfg.enabledPlugins;
  };
in {
  options.user.dev.claude-code = {
    enable = lib.mkEnableOption "Claude Code development tools";

    model = lib.mkOption {
      type = lib.types.str;
      default = "opus";
      description = "Claude model to use";
    };

    subagentModel = lib.mkOption {
      type = lib.types.str;
      default = "opus";
      description = "Claude model to use for subagents";
    };

    effortLevel = lib.mkOption {
      type = lib.types.str;
      default = "high";
      description = "Claude Code effort level to use";
    };

    enabledPlugins = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default =
        {
          "audio-notify@y0usaf-marketplace" = true;
          "instructify@y0usaf-marketplace" = true;
          "purr@ai-eng-plugins" = true;
          "skillify@ai-eng-plugins" = true;
          "skills-framework@ai-eng-plugins" = true;
          "the-chopper@ai-eng-plugins" = true;
        }
        // lib.optionalAttrs (ghEnabled && claudeCodeSkillEnabled "gh") {
          "gh@y0usaf-marketplace" = true;
        }
        // lib.optionalAttrs (claudeCodeSkillEnabled "linear-cli") {
          "linear-cli@y0usaf-marketplace" = true;
        }
        // lib.optionalAttrs (agentSlackEnabled && claudeCodeSkillEnabled "agent-slack") {
          "agent-slack@y0usaf-marketplace" = true;
        };
      description = ''
        Claude Code plugins keyed by `plugin@marketplace`.
        False values are omitted from the generated `settings.json`.
      '';
    };

    extraKnownMarketplaces = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = {
        "y0usaf-marketplace" = {
          source = {
            source = "directory";
            path = "${config.user.homeDirectory}/.config/claude";
          };
        };
        "ai-eng-plugins" = {
          source = {
            source = "git";
            owner = "Cook-Unity";
            repo = "ai-eng-plugins";
            url = "git@github.com:Cook-Unity/ai-eng-plugins.git";
          };
        };
        "claude-code-plugins" = {
          source = {
            source = "github";
            repo = "anthropics/claude-code";
          };
        };
      };
      description = "Additional Claude Code plugin marketplaces.";
    };

    skills =
      lib.mapAttrs (pluginName: _: {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to enable the `${pluginName}` Claude Code skill plugin.";
        };
      })
      (lib.filterAttrs (_: plugin: plugin ? skills) claudeCodePlugins);
  };

  config = lib.mkIf claudeCodeCfg.enable {
    environment.systemPackages =
      lib.optionals (!config.programs.tweakcc.enable) [pkgs.claude-code]
      ++ [
        (pkgs.writeShellScriptBin "bunclaude" ''
          exec ${pkgs.bun}/bin/bunx --bun @anthropic-ai/claude-code --allow-dangerously-skip-permissions "$@"
        '')
      ];

    bayt.users."${user.name}".files =
      ((claudeCodeConfig.marketplace {inherit lib;}).build {
        name = "y0usaf-marketplace";
        owner = {
          name = "y0usaf";
          email = "";
        };
        inherit (claudeCodeConfig) plugins;
        basePath = ".config/claude";
        description = "Personal Claude Code plugin marketplace";
        version = "1.0.0";
      })
      // {
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

        ".claude/settings.json" = {
          generator = lib.generators.toJSON {};
          value = settingsJson;
          clobber = true;
        };
      };

    programs.tweakcc = {
      enable = false;
      settings = {
        misc = {
          hideStartupBanner = true;
          expandThinkingBlocks = false;
        };
        claudeMdAltNames = ["AGENTS.md"];
      };
    };
  };
}
