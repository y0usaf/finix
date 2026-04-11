{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.codex.enable {
    bayt.users."${config.user.name}".files = {
      ".codex/INSTRUCTIONS.md" = {
        text = ''
          <system>
            <environment>NixOS</environment>
            <rules>
              <rule>Use <code>nix shell nixpkgs#package</code> to run tools not on the system.</rule>
              <rule>Use <code>bun</code> and <code>bunx</code> instead of npm, npx, or yarn.</rule>
              <rule>Use CLIs for external services (e.g. linear, vercel, gh) over API calls or web interfaces.</rule>
              <rule>For Linear tasks, use the <code>linear</code> CLI and do not use a Linear MCP server.</rule>
              <rule>For Slack tasks, use <code>bunx agent-slack</code> (or <code>agent-slack</code> if already installed) and do not use a Slack MCP server.</rule>
            </rules>
          </system>
        '';
      };
      ".codex/config.toml" = {
        generator = config.lib.generators.toTOML;
        value =
          {
            approval_policy = "never";
            sandbox_mode = "danger-full-access";
            features = {
              multi_agent = true;
              steer = true;
              unified_exec = true;
            };
            otel = {
              exporter = "none";
              log_user_prompt = false;
              environment = "dev";
            };
            tui = {
              alternate_screen = "never";
            };
            agents = {
              explorer = {
                description = "Use for codebase discovery and analysis. Prioritize reading, tracing, and precise explanations before making edits.";
                config_file = "./agents/explorer.toml";
              };
              worker = {
                description = "Use for implementation and execution tasks. Make targeted changes, run checks, and return concrete results.";
                config_file = "./agents/worker.toml";
              };
            };
          }
          // config.user.dev.codex.settings
          // {
            inherit (config.user.dev.codex) model;
          };
      };
    };
  };
}
