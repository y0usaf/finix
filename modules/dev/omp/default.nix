# omp (oh-my-pi) coding agent: upstream flake package + declarative harness
# config. The agent's own config lives in ~/.omp/agent/config.yml; the
# top-level ~/.omp/config.json belongs to the harness TUI surface (same split
# as ~/.pi/config.json for pi-harness), so managing it here can never fight
# the agent over a file.
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.dev.omp;
  # Same shared catalog pi uses (plain data, see modules/dev/pi/model-catalog.nix).
  catalog = import ../pi/model-catalog.nix;
  toJSON = lib.generators.toJSON {};
in {
  options.user.dev.omp = {
    enable = lib.mkEnableOption "omp (oh-my-pi) coding agent CLI";

    settings = lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = {};
      description = ''
        Keys merged into ~/.omp/config.json — the omp-harness surface:
        keybinds (e.g. keybinds.project_prev = "ctrl+h"),
        panel_width_percent, sidebar_width, right_rail_width, ascii,
        symbols.overrides. Missing keys fall back to built-in defaults.
      '';
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
      # Agent-side model config, same settings.json/models.json schema as pi.
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
    };
  };
}
