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
      flakeInputs.fx.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # fx rejects settings symlinked into the Nix store as durable_path_unsafe,
    # so deploy this as a real JSON file rather than a generated-file symlink.
    manzil.users."${config.user.name}".files.".fx/settings.json" = {
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
        input_appearance = "tint";
        slash_menu_categories = true;
        startup_scrollback = true;
        prompt_history.enabled = true;
        statusLine = {
          sandbox = true;
          context = true;
          session = true;
        };
        notifications = {
          turn_end = true;
          attention_required = true;
          max = false;
        };
        auto_upgrade = true;
        update_channel = "stable";
      };
    };
  };
}
