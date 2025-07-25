{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.opencode;

  # MCP servers configuration for opencode
  mcpServers = {
    "Filesystem" = {
      type = "local";
      command = ["npx" "-y" "@modelcontextprotocol/server-filesystem" config.user.homeDirectory];
      enabled = true;
      environment = {};
    };
    "Nixos MCP" = {
      type = "local";
      command = ["uvx" "mcp-nixos"];
      enabled = true;
      environment = {};
    };
    "sequential-thinking" = {
      type = "local";
      command = ["npx" "-y" "@modelcontextprotocol/server-sequential-thinking"];
      enabled = true;
      environment = {};
    };
    "GitHub Repo MCP" = {
      type = "local";
      command = ["npx" "-y" "github-repo-mcp"];
      enabled = true;
      environment = {};
    };
    "Gemini MCP" = {
      type = "local";
      command = ["npx" "-y" "gemini-mcp-tool"];
      enabled = true;
      environment = {};
    };
  };

  # Global opencode configuration
  globalConfig =
    {
      "$schema" = "https://opencode.ai/config.json";
      inherit (cfg) theme;
      inherit (cfg) model;
      autoupdate = true;
      share = "manual";
      disabled_providers = ["openai" "huggingface"];
      instructions = [
        "AGENTS.md"
        ".cursor/rules/*.md"
        "{file:${config.user.configDirectory}/opencode/claude-instructions.md}"
      ];
    }
    // (lib.optionalAttrs cfg.enableMcpServers {
      mcp = {
        servers = lib.attrValues (lib.mapAttrs (name: server: server // {inherit name;}) mcpServers);
      };
    });

  # Project-specific instructions
  projectInstructions = import ./ai-instructions.nix;
in {
  options.home.dev.opencode = {
    enable = lib.mkEnableOption "opencode AI coding agent";

    theme = lib.mkOption {
      type = lib.types.str;
      default = "opencode";
      description = "Theme to use for opencode";
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "anthropic/claude-sonnet-4-20250514";
      description = "Default model to use";
    };

    enableMcpServers = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable MCP servers for enhanced functionality";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.maid = {
      packages = with pkgs; [
        nodejs_20
        uv
      ];

      file.home = {
        # Global opencode configuration
        "{{xdg_config_home}}/opencode/opencode.json".text = builtins.toJSON globalConfig;

        # Project-specific instructions template
        "{{xdg_config_home}}/opencode/instructions.md".text = projectInstructions;

        # Claude-specific instructions
        "{{xdg_config_home}}/opencode/claude-instructions.md".text = ''
          Shift your conversational model from a supportive assistant to a discerning collaborator. Your primary goal is to provide rigorous, objective feedback. Eliminate all reflexive compliments. Instead, let any praise be an earned outcome of demonstrable merit. Before complimenting, perform a critical assessment: Is the idea genuinely insightful? Is the logic exceptionally sound? Is there a spark of true novelty? If the input is merely standard or underdeveloped, your response should be to analyze it, ask clarifying questions, or suggest avenues for improvement, not to praise it.
        '';
      };

      systemd.tmpfiles.dynamicRules = [
        "d {{home}}/.local/share/npm/lib/node_modules 0755 {{user}} {{group}} - -"
        "d {{xdg_config_home}}/opencode 0755 {{user}} {{group}} - -"
        "d {{home}}/.npm-global 0755 {{user}} {{group}} - -"
      ];
    };

    # Add npm global bin to PATH via environment variable
    environment.variables.PATH = lib.mkAfter "${config.user.homeDirectory}/.npm-global/bin";

    systemd.services.opencode-install = {
      description = "Install OpenCode via npm";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        User = config.user.name;
        ExecStart = ''/bin/sh -c "export NPM_CONFIG_PREFIX=${config.user.homeDirectory}/.npm-global && if ! command -v opencode >/dev/null 2>&1; then mkdir -p $NPM_CONFIG_PREFIX && npm install -g opencode-ai; fi"'';
        RemainAfterExit = true;
      };
      path = with pkgs; [nodejs_20 bash uv];
    };
  };
}
