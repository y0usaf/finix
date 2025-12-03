{
  config,
  lib,
  pkgs,
  ...
}: let
  claudeCodeConfig = import ../../../../lib/claude-code;

  # Build the marketplace with all plugins
  marketplaceFiles = claudeCodeConfig.marketplace {inherit lib;};
  marketplace = marketplaceFiles.build {
    name = "y0usaf-marketplace";
    owner = {
      name = "y0usaf";
      email = "";
    };
    plugins = claudeCodeConfig.plugins;
    basePath = ".config/claude"; # ~/.config/claude/
    description = "Personal Claude Code plugin marketplace";
    version = "1.0.0";
  };

  # Settings without hooks (hooks come from plugin now)
  settingsWithoutHooks = {
    inherit (claudeCodeConfig.settings) includeCoAuthoredBy env statusLine;
    model = config.user.dev.claude-code.model;
    enabledPlugins = {
      "audio-notify@y0usaf-marketplace" = true;
      "codex-mcp@y0usaf-marketplace" = true;
      "collab-flow@y0usaf-marketplace" = true;
      "instructions@y0usaf-marketplace" = true;
      "parallelization-instruct@y0usaf-marketplace" = true;
      "todowrite-instruct@y0usaf-marketplace" = true;
      "tool-tracker@y0usaf-marketplace" = true;
    };
    extraKnownMarketplaces = {
      "y0usaf-marketplace" = {
        source = {
          source = "directory";
          path = "/home/y0usaf/.config/claude";
        };
      };
    };
  };
in {
  imports = [./claude-code.nix];

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
      };
  };
}
