{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.dev.fx.enable = lib.mkEnableOption "fx coding agent";

  config = lib.mkIf config.user.dev.fx.enable {
    environment.systemPackages = [
      flakeInputs.oh-my-fx.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    manzil.users."${config.user.name}".files = {
      # Oh My Fx (the deployed `omfx` binary) both reads and rejects a global
      # rules file at $HOME/.fx/AGENTS.md: src/builtins/context.zig loads it as
      # <global-rules> on the initial context, but loadRule() omits a symlink
      # whose target resolves outside the file's own directory. A manzil
      # symlink into the Nix store is outside ~/.fx, so it would be silently
      # dropped; deploy a real file (type = "copy") instead.
      ".fx/AGENTS.md" = {
        type = "copy";
        clobber = true;
        text = config.user.dev.prompts.ethics + "\n\n" + config.user.dev.prompts.noTests;
      };

      # fx rejects settings symlinked into the Nix store as
      # durable_path_unsafe, so deploy these as real JSON files rather than
      # generated-file symlinks.
      ".fx/settings.json" = {
        type = "merge";
        format = "json";
        clobber = true;
        value = {
          model = "openai/gpt-5.6-luna";
          effort = "max";
          fast_mode = true;
          permission_mode = "yolo";
          yolo_acknowledged = true;
          sandbox = "none";
        };
      };

      # Oh My Fx keeps its own profile settings in ~/.omfx so fork-only keys
      # never collide with the upstream fx deployment above. Shared keys
      # mirror the fx values exactly; startup_mode is an Oh My Fx extension.
      ".omfx/settings.json" = {
        type = "merge";
        format = "json";
        clobber = true;
        value = {
          model = "openai/gpt-5.6-sol";
          effort = "xhigh";
          fast_mode = false;
          permission_mode = "yolo";
          yolo_acknowledged = true;
          max_agent_steps = 0;
          max_tool_result_bytes = 131072;
          first_call_tool_choice = "auto";
          context = true;
          context_limits = {
            skill_catalog_bytes = 16384;
            project_instructions_total_bytes = 131072;
          };
          sandbox = "none";
          slash_menu_categories = true;
          startup_scrollback = true;
          startup_mode = "mux";
          prompt_history.enabled = true;
        };
      };
    };
  };
}
