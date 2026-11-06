{
  config,
  inputPackages,
  ...
}: {
  user.persist.directories = [
    ".fx"
    ".omfx"
  ];
  environment.systemPackages = [inputPackages.oh-my-fx.default];

  user.files = {
    ".fx/AGENTS.md" = {
      type = "copy";
      clobber = true;
      text = config.user.dev.prompts.shared;
    };

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
}
