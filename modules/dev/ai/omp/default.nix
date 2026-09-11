# omp (oh-my-pi) coding agent: pi-flake's bundled build (omp-full: upstream
# omp wrapped with the shared pi extension bundle via PI_CONFIG_FILES) plus
# declarative harness config. The agent's own config lives in
# ~/.omp/agent/config.yml; the top-level ~/.omp/config.json belongs to the
# harness TUI surface.
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.dev.omp;
  catalog = config.user.dev.modelCatalog;
  toJSON = lib.generators.toJSON {};

  conditionValue = rule:
    if rule.condition != null
    then rule.condition
    else if rule.minOutputLength != null
    then ["(?s).{${toString rule.minOutputLength},}"]
    else null;
  frontmatter = rule:
    lib.filterAttrs (name: value:
      value
      != (
        if name == "globs"
        then []
        else null
      )) {
      condition = conditionValue rule;
      inherit (rule) astCondition scope globs interruptMode;
    };

  ruleFile = name: rule: {
    name = ".omp/agent/rules/${name}.md";
    value.text = let
      frontmatterValue = frontmatter rule;
      yaml = lib.generators.toYAML {} frontmatterValue;
    in "${lib.optionalString (frontmatterValue != {}) "---\n${yaml}---\n\n"}${rule.content}\n";
  };
in {
  options.user.dev.omp = {
    enable = lib.mkEnableOption "omp (oh-my-pi) coding agent CLI";

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Keys merged into ~/.omp/config.json.";
    };

    ttsrRules = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (_: {
        options = {
          content = lib.mkOption {
            type = lib.types.lines;
            description = "Reminder injected when this TTSR matches.";
          };
          condition = lib.mkOption {
            type = lib.types.nullOr (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
            default = null;
            description = "Regex condition(s) matched against OMP streams.";
          };
          minOutputLength = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.positive;
            default = null;
            description = "Minimum streamed output characters before this TTSR matches.";
          };
          astCondition = lib.mkOption {
            type = lib.types.nullOr (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
            default = null;
            description = "ast-grep pattern(s) matched against edit/write streams.";
          };
          scope = lib.mkOption {
            type = lib.types.nullOr (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
            default = null;
            description = "TTSR stream scope, for example text.";
          };
          globs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "File globs limiting this rule.";
          };
          interruptMode = lib.mkOption {
            type = lib.types.nullOr (lib.types.enum ["never" "prose-only" "tool-only" "always"]);
            default = null;
            description = "Per-rule interrupt behavior.";
          };
        };
      }));
      default = {};
      description = "TTSR rules written to ~/.omp/agent/rules/<name>.md.";
    };
    advisor = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Advisor on/off. Merged into ~/.omp/agent/config.yml at activation (manzil merge; TUI rewrites survive, keys re-merge).";
      };
      model = lib.mkOption {
        type = lib.types.str;
        default = "vercel-ai-gateway/openai/gpt-5.6-luna";
        description = "Model id assigned to the advisor role.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # pi-flake's omp-full: upstream omp (can1357/oh-my-pi flake build)
    # wrapped with the shared pi extension bundle (chronobreak,
    # vercel-ai-gateway, recap, donsetch) injected via PI_CONFIG_FILES.
    # Note: the bundle overlay's extensions array is authoritative for this
    # build; it replaces any extensions list in user config layers.
    environment.systemPackages = [
      flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".omp-full
    ];

    manzil.users."${config.user.name}".files =
      {
        # Native model defaults and advisor settings belong in config.yml;
        # OMP ignores legacy settings.json when this file exists.
        # omp persists /config edits here, so a symlink would break its atomic
        # save (temp-file + rename next to the target). merge keeps the file
        # writable, preserves TUI keys, and re-applies ours on every switch.
        ".omp/agent/config.yml" = {
          type = "merge";
          format = "yaml";
          clobber = true;
          value = {
            inherit (catalog) defaultThinkingLevel;
            advisor.enabled = cfg.advisor.enable;
            modelRoles.default = "${catalog.defaultProvider}/${catalog.defaultModel}";
            modelRoles.advisor = cfg.advisor.model;
          };
        };
        ".omp/config.json" = {
          generator = toJSON;
          value = cfg.settings;
        };
        ".omp/agent/settings.json" = {
          generator = toJSON;
          value = {
            inherit (catalog) defaultProvider;
            inherit (catalog) defaultModel;
            inherit (catalog) defaultThinkingLevel;
            inherit (catalog) enabledModels;
            packages = [
              "/home/y0usaf/dev/maintaining/pi-flake/extensions/pi-vercel-ai-gateway"
            ];
          };
        };
        ".omp/agent/models.json" = {
          generator = toJSON;
          value = catalog.models;
        };
      }
      // lib.listToAttrs (lib.mapAttrsToList ruleFile cfg.ttsrRules);
  };
}
