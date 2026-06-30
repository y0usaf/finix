{
  config,
  lib,
  ...
}: let
  inherit (config) user;
  claudeCodeCfg = user.dev.claude-code;
  vercelAiGatewayCfg = claudeCodeCfg.providers."vercel-ai-gateway";
  providerCfg =
    if vercelAiGatewayCfg.enable
    then vercelAiGatewayCfg
    else claudeCodeCfg.apiGateway;

  ccSettings = {
    includeCoAuthoredBy = false;
    promptSuggestionEnabled = false;
    skipDangerousModePermissionPrompt = true;
    # Standing opt-in: xhigh effort + dynamic-workflow orchestration,
    # so the "ultracode" prompt keyword isn't needed each turn.
    ultracode = true;
    permissions = {
      defaultMode = "bypassPermissions";
    };
    env = {
      DISABLE_TELEMETRY = "1";
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
    };
  };
in {
  config = lib.mkIf claudeCodeCfg.enable {
    manzil.users."${user.name}".files =
      {
        ".claude/on-agent-need-attention.wav" = {
          source = ./assets/tuturu.ogg;
        };

        ".claude/on-agent-complete.wav" = {
          source = ./assets/tuturu.ogg;
        };

        ".claude/CLAUDE.md" = {
          text = ''
            <system>
              <environment>NixOS</environment>
              <rules>
                <rule>Use <code>nix shell -p <package></code> to run tools not on the system.</rule>
                <rule>Use <code>bun</code> and <code>bunx</code> instead of npm, npx, or yarn.</rule>
                <rule>Use CLIs for external services (e.g. linear, vercel, gh) over API calls or web interfaces.</rule>
                <rule>For Linear tasks, use the <code>linear</code> CLI and do not use a Linear MCP server.</rule>
              </rules>
            </system>
          '';
        };

        ".claude/settings.json" = {
          generator = lib.generators.toJSON {};
          value =
            {
              inherit (claudeCodeCfg) model effortLevel extraKnownMarketplaces;
              inherit
                (ccSettings)
                includeCoAuthoredBy
                permissions
                promptSuggestionEnabled
                skipDangerousModePermissionPrompt
                ultracode
                ;
              # Real auto-memory toggle. The schema key is the top-level boolean
              # `autoMemoryEnabled` (defaults to true in Claude Code); the old
              # `memory = { enabled = false; }` key was a silent no-op.
              inherit (claudeCodeCfg.memory) autoMemoryEnabled;
              env =
                ccSettings.env
                // {
                  CLAUDE_CODE_SUBAGENT_MODEL = claudeCodeCfg.subagentModel;
                }
                // lib.optionalAttrs claudeCodeCfg.memory.disableClaudeMdFiles {
                  CLAUDE_CODE_DISABLE_CLAUDE_MDS = "1";
                }
                // lib.optionalAttrs (providerCfg.baseUrl != "") {
                  ANTHROPIC_BASE_URL = providerCfg.baseUrl;
                  # Claude Code prefers a non-empty ANTHROPIC_API_KEY over
                  # ANTHROPIC_AUTH_TOKEN — force it empty so the gateway token wins.
                  ANTHROPIC_API_KEY = "";
                }
                // providerCfg.models
                // providerCfg.extraEnv;
              enabledPlugins = lib.filterAttrs (_: enabled: enabled) claudeCodeCfg.enabledPlugins;
            }
            // lib.optionalAttrs (claudeCodeCfg.memory.autoMemoryDirectory != null) {
              inherit (claudeCodeCfg.memory) autoMemoryDirectory;
            };
        };
      }
      // lib.optionalAttrs (providerCfg.apiKeyFile != null) {
        ".config/nushell/env.nu" = {
          text = lib.mkAfter ''
            $env.ANTHROPIC_AUTH_TOKEN = (open "${providerCfg.apiKeyFile}" | str trim)
          '';
        };
      };
  };
}
