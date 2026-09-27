{
  config,
  lib,
  ...
}: let
  catalog = config.user.dev.modelCatalog;
  toJSON = lib.generators.toJSON {};
in {
  config = lib.mkIf config.user.dev.pi.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".config/pi/agent"
      ".config/pi-harness"
      ".local/share/pi"
      ".local/state/pi-harness"
      ".pi"
    ];
    manzil.users."${config.user.name}".files = {
      ".pi/agent/settings.json" = {
        generator = toJSON;
        value = {
          inherit (catalog) defaultProvider defaultModel defaultThinkingLevel enabledModels;
          packages = [
            "/home/y0usaf/dev/maintaining/pi-flake/extensions/pi-vercel-ai-gateway"
          ];
          compaction.enabled = false;
          showHardwareCursor = true;
          editorPaddingX = 0;
          steeringMode = "one-at-a-time";
          transport = "sse";
          skills = [
            "${./skills}"
          ];
          options = {
            skills_paths = [
              "./.codex/skills"
              "./.claude/skills"
            ];
          };
          hideThinkingBlock = true;
          collapseChangelog = true;
          quietStartup = true;
          doubleEscapeAction = "tree";
          treeFilterMode = "default";
          extensionSettings = {
            "codex-fast" = false;
            "pi-compact" = {
              tools = {
                mode = "compact";
                gap = false;
              };
              user = {
                mode = "borderless";
                gap = true;
              };
            };
          };
          symbols = {
            preset = "ascii";
            overrides = {};
          };
          recap = {
            placement = "above";
          };
        };
      };
      ".pi/agent/models.json" = {
        generator = toJSON;
        value = catalog.models;
      };
    };
  };
}
