{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.claude-code = {
    enable = lib.mkEnableOption "Claude Code development tools";
  };

  config = lib.mkIf config.user.dev.claude-code.enable {
    environment.systemPackages = [
      pkgs.claude-code
    ];
    usr = {
      files = {
        ".claude/output-styles/explanatory.md" = {
          text = (import ./output-styles.nix {inherit config lib pkgs;}).explanatoryOutputStyle;
          clobber = true;
        };
        ".claude/CLAUDE.md" = {
          text = (import ./instructions.nix {inherit config lib pkgs;}).claudeInstructions;
          clobber = true;
        };
        ".config/claude/claude_desktop_config.json" = {
          text = builtins.toJSON (import ./mcp-config.nix {inherit config lib pkgs;}).mcpConfig;
          clobber = true;
        };
        ".claude/settings.json" = {
          text = builtins.toJSON (import ./settings.nix {inherit config lib pkgs;}).claudeSettings;
          clobber = true;
        };
        ".claude/statusline.sh" = {
          text = (import ./statusline.nix {inherit config lib pkgs;}).statuslineScript;
          executable = true;
          clobber = true;
        };
      };
    };
  };
}
