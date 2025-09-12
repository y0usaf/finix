{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.claude-code;

  instructions = import ./instructions.nix {inherit config lib pkgs;};
  outputStyles = import ./output-styles.nix {inherit config lib pkgs;};
  mcpConfig = import ./mcp-config.nix {inherit config lib pkgs;};
  settings = import ./settings.nix {inherit config lib pkgs;};
  statusline = import ./statusline.nix {inherit config lib pkgs;};
in {
  options.home.dev.claude-code = {
    enable = lib.mkEnableOption "Claude Code development tools";
  };

  config = lib.mkIf cfg.enable {
    usr = {
      packages = with pkgs; [
        claude-code
      ];
      files = {
        ".claude/output-styles/explanatory.md" = {
          text = outputStyles.explanatoryOutputStyle;
          clobber = true;
        };
        ".claude/CLAUDE.md" = {
          text = instructions.claudeInstructions;
          clobber = true;
        };
        ".config/claude/claude_desktop_config.json" = {
          text = builtins.toJSON mcpConfig.mcpConfig;
          clobber = true;
        };
        ".claude/settings.json" = {
          text = builtins.toJSON settings.claudeSettings;
          clobber = true;
        };
        ".claude/statusline.sh" = {
          text = statusline.statuslineScript;
          executable = true;
          clobber = true;
        };
      };
    };
  };
}
