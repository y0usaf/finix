{lib, ...}: {
  options.user.dev.ompPrompts = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    readOnly = true;
    description = "Zero-prompt OMP agent definitions.";
  };

  config.user.dev.ompPrompts.taskAgent = ''
    ---
    name: "task"
    description: "General-purpose helper"
    spawns: "*"
    model: "@task"
    thinking-level: "auto"
    ---
  '';
}
