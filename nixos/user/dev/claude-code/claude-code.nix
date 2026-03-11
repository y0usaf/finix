{
  config,
  lib,
  pkgs,
  ...
}: let
  claudeCodeConfig = import ../../../../lib/claude-code;
  skillPlugins = lib.filterAttrs (_pluginName: plugin: plugin ? skills) claudeCodeConfig.plugins;
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

    skills =
      lib.mapAttrs (pluginName: _plugin: {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to enable the `${pluginName}` Claude Code skill plugin.";
        };
      })
      skillPlugins;
  };

  config = lib.mkIf config.user.dev.claude-code.enable {
    environment.systemPackages =
      lib.optionals (!config.programs.tweakcc.enable) [pkgs.claude-code]
      ++ [
        (pkgs.writeShellScriptBin "bunclaude" ''
          exec ${pkgs.bun}/bin/bunx --bun @anthropic-ai/claude-code --allow-dangerously-skip-permissions "$@"
        '')
      ];
  };
}
