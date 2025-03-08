#===============================================================================
#                      🤖 Claude Desktop Configuration 🤖
#===============================================================================
# Anthropic's Claude AI assistant desktop application for Linux
# This is an unofficial build using the flake from k3d3/claude-desktop-linux-flake
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  inputs,
  ...
}: {
  config = {
    # Add Claude Desktop to home packages
    home.packages = [
      # We'll use the claude-desktop-with-fhs package to ensure compatibility
      # with any potential MCP servers that might need npx, uvx, or docker
      inputs.claude-desktop.packages.${pkgs.system}.claude-desktop-with-fhs
    ];

    # Create desktop entry with proper icon and categories
    xdg.desktopEntries = {
      "claude-desktop" = {
        name = "Claude Desktop";
        exec = "claude-desktop %U";
        terminal = false;
        categories = ["Development" "Utility"];
        comment = "Anthropic's Claude AI assistant";
        # The icon is included in the package
      };
    };

    # Add environment variables if needed
    programs.zsh = lib.mkIf config.programs.zsh.enable {
      envExtra = ''
        # Claude Desktop environment variables
        export CLAUDE_DESKTOP_WAYLAND=1
      '';
    };
  };
}
