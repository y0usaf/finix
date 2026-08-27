{
  config,
  lib,
  ...
}: let
  cfg = config.user.dev.pi;
  toJSON = lib.generators.toJSON {};
in {
  config = lib.mkIf cfg.enable {
    manzil.users."${config.user.name}".files = {
      ".pi/agent/settings.json" = {
        generator = toJSON;
        value =
          {
            inherit (cfg) defaultProvider;
            inherit (cfg) defaultModel;
            inherit (cfg) defaultThinkingLevel;
            inherit (cfg) enabledModels;
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
          }
          // lib.optionalAttrs (cfg.extensionSettings != {}) {
            inherit (cfg) extensionSettings;
          }
          // cfg.settings;
      };
      ".pi/agent/models.json" = {
        generator = toJSON;
        value = cfg.models;
      };
    };
  };
}
