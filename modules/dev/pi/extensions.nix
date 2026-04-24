{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.user.dev.pi;

  # Extension packages from flake inputs
  piMonoPkg = flakeInputs."pi-mono".packages."${system}".default;
  piAgentsPkg = flakeInputs."pi-agents".packages."${system}".default;
  piCodexFastPkg = flakeInputs."pi-codex-fast-flake".packages."${system}".default;
  piRtkPkg = flakeInputs."pi-rtk-flake".packages."${system}".default;
  piCompactToolsPkg = flakeInputs."pi-compact-tools".packages."${system}".default;
  piToolManagementPkg = flakeInputs."pi-tool-management".packages."${system}".default;

  # Extension packages in order
  extensionPackages =
    [
      piAgentsPkg
      piCodexFastPkg
    ]
    ++ lib.optionals cfg.rtk.enable [
      piRtkPkg
    ]
    ++ [
      piCompactToolsPkg
      piToolManagementPkg
    ];

  # Documentation paths from pi-mono (used by prompts.nix)
  docPaths = {
    readme = "${piMonoPkg}/share/pi/README.md";
    docs = "${piMonoPkg}/share/pi/docs";
    examples = "${piMonoPkg}/share/pi/examples";
  };

  # Extension settings for codex-fast and pi-compact
  extensionSettings =
    {
      "codex-fast" = {
        enabled = true;
        supportedModels = ["gpt-5.5"];
      };
      "pi-compact" =
        {
          tools = cfg.compactness.tools;
          user = cfg.compactness.user;
        }
        // lib.optionalAttrs (cfg.compactness.toolColour != null) {
          tool_colour = cfg.compactness.toolColour;
        }
        // lib.optionalAttrs (cfg.compactness.userColour != null) {
          user_colour = cfg.compactness.userColour;
        };
    }
    // cfg.extensionSettings;

  # Settings object written to settings.json
  piSettings = {
    defaultProvider = "cerebras";
    defaultModel = "zai-glm-4.7";
    defaultThinkingLevel = "off";
    enabledModels = [
      "cerebras/zai-glm-4.7:off"
      "openai-codex/gpt-5.5:xhigh"
      "anthropic/claude-opus-4-7:xhigh"
    ];
    compaction.enabled = false;
    showHardwareCursor = true;
    editorPaddingX = 0;
    steeringMode = "one-at-a-time";
    transport = "sse";
    hideThinkingBlock = true;
    collapseChangelog = true;
    quietStartup = false;

    doubleEscapeAction = "tree";
    treeFilterMode = "default";
    theme = "dark";
    packages = map (p: "${p}") extensionPackages;
  };
in {
  config = lib.mkIf cfg.enable {
    user.dev.pi = {
      readmePath = docPaths.readme;
      docsPath = docPaths.docs;
      examplesPath = docPaths.examples;
    };

    environment.variables = {
      PI_SKIP_VERSION_CHECK = "1";
      PI_AGENTS_PACKAGE = "${piAgentsPkg}";
    };

    environment.systemPackages =
      [
        piMonoPkg
      ]
      ++ lib.optionals cfg.rtk.enable [
        pkgs.rtk
      ];

    bayt.users."${config.user.name}".files =
      {
        ".pi/agent/settings.json" = {
          text = builtins.toJSON piSettings;
        };
      }
      // lib.optionalAttrs (extensionSettings != {}) {
        ".pi/agent/extension-settings.json" = {
          text = builtins.toJSON extensionSettings;
        };
      };
  };
}
