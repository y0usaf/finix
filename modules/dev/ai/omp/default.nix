# omp (oh-my-pi) coding agent: upstream flake package + declarative harness
# config. The agent's own config lives in ~/.omp/agent/config.yml; the
# top-level ~/.omp/config.json belongs to the harness TUI surface.
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.dev.omp;
  catalog = import ../pi/model-catalog.nix;
  toJSON = lib.generators.toJSON {};

  ruleFile = name: rule: {
    name = ".omp/agent/rules/${name}.md";
    value.text = let
      frontmatter =
        lib.optionalAttrs (rule.condition != null) { inherit (rule) condition; }
        // lib.optionalAttrs (rule.minOutputLength != null && rule.condition == null) {
          condition = ["(?s).{${toString rule.minOutputLength},}"];
        }
        // lib.optionalAttrs (rule.astCondition != null) { inherit (rule) astCondition; }
        // lib.optionalAttrs (rule.scope != null) { inherit (rule) scope; }
        // lib.optionalAttrs (rule.globs != []) { inherit (rule) globs; }
        // lib.optionalAttrs (rule.interruptMode != null) { inherit (rule) interruptMode; };
      yaml = lib.generators.toYAML {} frontmatter;
    in "${lib.optionalString (frontmatter != {}) "---\n${yaml}---\n\n"}${rule.content}\n";
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
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      flakeInputs.oh-my-pi.packages."${pkgs.stdenv.hostPlatform.system}".omp
    ];

    manzil.users."${config.user.name}".files = {
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
        };
      };
      ".omp/agent/models.json" = {
        generator = toJSON;
        value = catalog.models;
      };
    } // lib.listToAttrs (lib.mapAttrsToList ruleFile cfg.ttsrRules);
  };
}
