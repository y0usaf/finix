# OpenCode configuration options for shared use across systems
# Provides option definitions that Darwin and NixOS can reference
{lib}: {
  options.dev.opencode = {
    enable = lib.mkEnableOption "OpenCode CLI for LLM interaction";

    provider = lib.mkOption {
      type = lib.types.enum ["ollama" "anthropic"];
      default = "ollama";
      description = "Default LLM provider to use";
    };

    baseURL = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:11434/v1";
      description = "Base URL for Ollama endpoint";
    };
  };

  config = lib.mkIf (lib.hasAttrByPath ["dev" "opencode" "enable"] && lib.getAttrFromPath ["dev" "opencode" "enable"] true) {
    # Placeholder for shared configuration
  };
}
