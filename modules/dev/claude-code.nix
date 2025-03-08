#===============================================================================
#                      🖋️ Code Cursor IDE Configuration 🖋️
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = {
    # Ensure npm is installed
    home.packages = with pkgs; [
      nodejs_20
    ];

    # Install Claude Code and Brave Search via npm
    home.activation.installClaudeCode = lib.hm.dag.entryAfter ["npmSetup"] ''
      # Install Claude Code and Brave Search globally via npm
      ${pkgs.nodejs_20}/bin/npm install -g @anthropic-ai/claude-code @modelcontextprotocol/server-brave-search
    '';

    # Add npm bin directory to PATH to ensure claude-code is accessible
    home.sessionPath = [
      "${config.xdg.dataHome}/npm/bin"
    ];
  };
}
