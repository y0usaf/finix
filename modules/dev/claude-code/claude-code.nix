{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) attrByPath mkEnableOption mkIf mkOption optionals optionalAttrs types;
  inherit (types) anything attrsOf bool str;
  inherit (config) user;

  claudeCodeCfg = user.dev.claude-code;

  claudeCodeSkillEnabled = skillName:
    attrByPath ["user" "dev" "claude-code" "skills" skillName "enable"] true config;
in {
  options.user.dev.claude-code = {
    enable = mkEnableOption "Claude Code development tools";

    model = mkOption {
      type = str;
      default = "opus";
      description = "Claude model to use";
    };

    subagentModel = mkOption {
      type = str;
      default = "opus";
      description = "Claude model to use for subagents";
    };

    effortLevel = mkOption {
      type = str;
      default = "high";
      description = "Claude Code effort level to use";
    };

    plugins = mkOption {
      type = attrsOf anything;
      default = {};
      description = "Local Claude Code marketplace plugin definitions.";
    };

    enabledPlugins = mkOption {
      type = attrsOf bool;
      default =
        {
          "audio-notify@y0usaf-marketplace" = true;
          "instructify@y0usaf-marketplace" = true;
          "purr@ai-eng-plugins" = true;
          "skillify@ai-eng-plugins" = true;
          "skills-framework@ai-eng-plugins" = true;
          "the-chopper@ai-eng-plugins" = true;
        }
        // optionalAttrs ((attrByPath ["user" "tools" "gh" "enable"] false config) && claudeCodeSkillEnabled "gh") {
          "gh@y0usaf-marketplace" = true;
        }
        // optionalAttrs (claudeCodeSkillEnabled "linear-cli") {
          "linear-cli@y0usaf-marketplace" = true;
        }
        // optionalAttrs ((attrByPath ["user" "dev" "work" "agent-slack" "enable"] false config) && claudeCodeSkillEnabled "agent-slack") {
          "agent-slack@y0usaf-marketplace" = true;
        };
      description = ''
        Claude Code plugins keyed by `plugin@marketplace`.
        False values are omitted from the generated `settings.json`.
      '';
    };

    extraKnownMarketplaces = mkOption {
      type = attrsOf (attrsOf anything);
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

    skills = mkOption {
      type = attrsOf (types.submodule {
        options.enable = mkOption {
          type = bool;
          default = true;
          description = "Whether to enable this Claude Code skill plugin.";
        };
      });
      default = {};
      description = "Per-skill Claude Code enable switches.";
    };
  };

  config = mkIf claudeCodeCfg.enable {
    environment.systemPackages =
      optionals (!config.programs.tweakcc.enable) [pkgs.claude-code]
      ++ [
        (pkgs.writeShellScriptBin "bunclaude" ''
          exec ${pkgs.bun}/bin/bunx --bun @anthropic-ai/claude-code --allow-dangerously-skip-permissions "$@"
        '')
      ];

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
