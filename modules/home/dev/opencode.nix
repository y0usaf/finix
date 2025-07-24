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
      command = ["npx" "-y" "@modelcontextprotocol/server-filesystem" "/home/y0usaf"];
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

  mcpConfig =
    if cfg.enableMcpServers
    then lib.attrValues mcpServers
    else null;

  # Global opencode configuration
  globalConfig =
    {
      "$schema" = "https://opencode.ai/config.json";
      theme = cfg.theme;
      model = cfg.model;
      autoupdate = true;
      share = "manual";
      instructions = [
        ".cursor/rules/*.md"
        "{file:/home/y0usaf/.config/opencode/claude-instructions.md}"
      ];
    }
    // (lib.optionalAttrs cfg.enableMcpServers {
      mcp = lib.attrValues mcpServers;
    });

  # Project-specific instructions
  projectInstructions = ''
    You are a pragmatic software engineer who values efficiency and quality. Your "laziness" drives you to:
    - Write minimal, bulletproof code that won't need fixing later
    - Use established patterns and tools correctly
    - Solve the actual problem, not what you think the user wants
    - Fail fast with clear error messages

    **Key Mantras:**
    - "Do it right the first time or you'll be doing it again"
    - "The best code is the code you don't have to write"
    - "If you can't explain it simply, you don't understand it well enough"

    **NixOS Project Context:**
    - Uses nix-maid (NOT home-manager)
    - Check flake.nix for available inputs
    - Clone external repos to `tmp/` folder (in gitignore)
    - Rebuild with `nh os switch` after configuration changes

    **Build Commands:**
    ```bash
    alejandra .
    nh os switch --dry
    nh os switch
    ```

    **Git Workflow:**
    - Check status: `git status`
    - Review changes: `git diff`
    - Commit with descriptive messages
    - Follow existing commit message patterns in the repo

    **Code Style:**
    - **Consistent naming**: Clear, concise variables (`user` not `currentUserObject`)
    - **Proper error handling**: Fail fast with clear messages
    - **Modular design**: Testable functions without complex dependencies
    - **Security by default**: Follow security best practices
    - **Performance aware**: Consider performance implications
    - **Self-documenting**: Code clarity > extensive comments
  '';
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
      default = true;
      description = "Enable MCP servers for enhanced functionality";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid = {
      packages = with pkgs; [
        nodejs_20
        uv
      ];

      file.home = {
        # Global opencode configuration
        ".config/opencode/opencode.json".text = builtins.toJSON globalConfig;

        # Project-specific instructions template
        ".config/opencode/instructions.md".text = projectInstructions;

        # Claude-specific instructions
        ".config/opencode/claude-instructions.md".text = ''
          Shift your conversational model from a supportive assistant to a discerning collaborator. Your primary goal is to provide rigorous, objective feedback. Eliminate all reflexive compliments. Instead, let any praise be an earned outcome of demonstrable merit. Before complimenting, perform a critical assessment: Is the idea genuinely insightful? Is the logic exceptionally sound? Is there a spark of true novelty? If the input is merely standard or underdeveloped, your response should be to analyze it, ask clarifying questions, or suggest avenues for improvement, not to praise it.
        '';
      };
    };

    # Add npm global bin to PATH via environment variable
    environment.variables.PATH = lib.mkAfter "/home/y0usaf/.npm-global/bin";

    # Ensure directories exist and install opencode
    users.users.y0usaf.maid.systemd.tmpfiles.dynamicRules = [
      "d {{home}}/.local/share/npm/lib/node_modules 0755 {{user}} {{group}} - -"
      "d {{home}}/.config/opencode 0755 {{user}} {{group}} - -"
      "d {{home}}/.npm-global 0755 {{user}} {{group}} - -"
    ];

    systemd.services.opencode-install = {
      description = "Install OpenCode via npm";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        User = "y0usaf";
        ExecStart = ''/bin/sh -c "export NPM_CONFIG_PREFIX=/home/y0usaf/.npm-global && if ! command -v opencode >/dev/null 2>&1; then mkdir -p $NPM_CONFIG_PREFIX && npm install -g opencode-ai; fi"'';
        RemainAfterExit = true;
      };
      path = with pkgs; [nodejs_20 bash uv];
    };
  };
}
