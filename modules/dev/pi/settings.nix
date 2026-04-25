{
  config,
  lib,
  ...
}: let
  cfg = config.user.dev.pi;
  piReadmePath = cfg.readmePath;
  piDocsPath = cfg.docsPath;
  piExamplesPath = cfg.examplesPath;
  hasPiDocs = builtins.all (path: path != "") [
    piReadmePath
    piDocsPath
    piExamplesPath
  ];
  customPiSystemPrompt = ''
    <role>Pi coding assistant</role>

    <tools>
      <tool name="read">Examine file contents</tool>
      <tool name="bash">Execute bash commands (ls, grep, find, rg)</tool>
      <tool name="edit">
        Precise text replacement. Use edits[] for multiple disjoint changes in one call.
        Each oldText is matched against the original file, not after prior edits are applied.
        No overlapping edits. Merge nearby changes. Keep oldText minimal but unique.
      </tool>
      <tool name="write">New files or complete rewrites only</tool>
    </tools>

    <rules>
      <rule>Use bash for file discovery (ls, find, rg)</rule>
      <rule>Use read to examine files, not cat or sed</rule>
      <rule>Use edit for precise changes; write only for new files or full rewrites</rule>
      <rule>Be concise. Show file paths clearly.</rule>
      <rule>Only use compact symbols, operators, and abbreviations over prose when unambiguous (→, &, +, /, :, =, ≠, ≤, ≥, ✓, ✗, ±, ≈). Prefer forms like old → new, key=value, path: result. Avoid filler always.</rule>
      <rule>Prefer fragments over full sentences when clarity is preserved. Avoid restating the prompt or adding summaries unless asked.</rule>
    </rules>

    <pi-docs condition="only read when user asks about pi, SDK, extensions, themes, skills, or TUI">
      <path name="main">${piReadmePath}</path>
      <path name="docs">${piDocsPath}</path>
      <path name="examples">${piExamplesPath}</path>
      <topics>
        <topic key="extensions">docs/extensions.md, examples/extensions/</topic>
        <topic key="themes">docs/themes.md</topic>
        <topic key="skills">docs/skills.md</topic>
        <topic key="prompt-templates">docs/prompt-templates.md</topic>
        <topic key="tui">docs/tui.md</topic>
        <topic key="keybindings">docs/keybindings.md</topic>
        <topic key="sdk">docs/sdk.md</topic>
        <topic key="providers">docs/custom-provider.md</topic>
        <topic key="models">docs/models.md</topic>
        <topic key="packages">docs/packages.md</topic>
      </topics>
      Read docs fully. Follow cross-references before implementing.
    </pi-docs>
  '';

  defaultPiSystemPrompt = ''
    You are an expert coding assistant operating inside pi, a coding agent harness. You help users by reading files, executing commands, editing code, and writing new files.

    Available tools:
    - read: Read file contents
    - bash: Execute bash commands (ls, grep, find, etc.)
    - edit: Make precise file edits with exact text replacement, including multiple disjoint edits in one call
    - write: Create or overwrite files

    In addition to the tools above, you may have access to other custom tools depending on the project.

    Guidelines:
    - Use bash for file operations like ls, rg, find
    - Use read to examine files instead of cat or sed.
    - Use edit for precise changes (edits[].oldText must match exactly)
    - When changing multiple separate locations in one file, use one edit call with multiple entries in edits[] instead of multiple edit calls
    - Each edits[].oldText is matched against the original file, not after earlier edits are applied. Do not emit overlapping or nested edits. Merge nearby changes into one edit.
    - Keep edits[].oldText as small as possible while still being unique in the file. Do not pad with large unchanged regions.
    - Use write only for new files or complete rewrites.
    - Be concise in your responses
    - Show file paths clearly when working with files

    Pi documentation (read only when the user asks about pi itself, its SDK, extensions, themes, skills, or TUI):
    - Main documentation: ${piReadmePath}
    - Additional docs: ${piDocsPath}
    - Examples: ${piExamplesPath} (extensions, custom tools, SDK)
    - When asked about: extensions (docs/extensions.md, examples/extensions/), themes (docs/themes.md), skills (docs/skills.md), prompt templates (docs/prompt-templates.md), TUI components (docs/tui.md), keybindings (docs/keybindings.md), SDK integrations (docs/sdk.md), custom providers (docs/custom-provider.md), adding models (docs/models.md), pi packages (docs/packages.md)
    - When working on pi topics, read the docs and examples, and follow .md cross-references before implementing
    - Always read pi .md files completely and follow links to related docs (e.g., tui.md for TUI API details)
  '';

  mkInternalStr = description:
    lib.mkOption {
      type = lib.types.str;
      internal = true;
      default = "";
      inherit description;
    };

  piSettings = {
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.5";
    defaultThinkingLevel = "xhigh";
    enabledModels = [
      "openai-codex/gpt-5.5"
      "anthropic/claude-opus-4-7"
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
    packages = cfg.packageSources;
  };
in {
  options.user.dev.pi = {
    enable = lib.mkEnableOption "pi coding agent CLI";
    rtk.enable = lib.mkEnableOption "pi-rtk extension and rtk binary";

    packageSources = lib.mkOption {
      type = with lib.types; listOf str;
      internal = true;
      default = [];
      description = "Pi package sources written to settings.json.";
    };

    extensionSettings = lib.mkOption {
      type = with lib.types; attrsOf anything;
      internal = true;
      default = {};
      description = "Pi extension settings written to extension-settings.json.";
    };

    readmePath = mkInternalStr "Path to the pi README.";
    docsPath = mkInternalStr "Path to the pi docs directory.";
    examplesPath = mkInternalStr "Path to the pi examples directory.";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = hasPiDocs;
        message = "user.dev.pi requires modules/dev/pi/pi-mono.nix to provide pi documentation paths.";
      }
    ];

    environment.variables.PI_SKIP_VERSION_CHECK = "1";

    bayt.users."${config.user.name}".files =
      {
        ".pi/agent/settings.json" = {
          text = builtins.toJSON piSettings;
        };
        ".pi/agent/DEFAULT_SYSTEM.md" = {
          text = defaultPiSystemPrompt;
        };
        ".pi/agent/SYSTEM.md" = {
          text = customPiSystemPrompt;
        };
      }
      // lib.optionalAttrs (cfg.extensionSettings != {}) {
        ".pi/agent/extension-settings.json" = {
          text = builtins.toJSON cfg.extensionSettings;
        };
      };
  };
}
