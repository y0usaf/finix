{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.crush = {
    enable = lib.mkEnableOption "crush package";
  };

  config = lib.mkIf config.user.dev.crush.enable {
    environment.systemPackages = [
      pkgs.crush
    ];

    # Crush folds global context files into its system prompt via
    # options.global_context_paths, whose default is ~/.config/crush/CRUSH.md
    # plus ~/.config/AGENTS.md (internal/config/load.go setDefaults; consumed by
    # internal/agent/prompt/prompt.go loadContextFiles -> processContextPath).
    # Deploying CRUSH.md ships the shared compaction/ethics and no-test-authoring
    # blocks through that native channel; crush.json is untouched so user options
    # and defaults stay.
    manzil.users."${config.user.name}".files.".config/crush/CRUSH.md".text =
      config.user.dev.prompts.ethics + "\n\n" + config.user.dev.prompts.noTests;
  };
}
