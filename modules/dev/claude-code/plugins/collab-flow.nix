_: {
  config.user.dev.claude-code.plugins = {
    collab-flow = {
      name = "collab-flow";
      version = "1.0.0";
      description = "Reminders to use AskUserQuestion for collaboration";
      author = {
        name = "y0usaf";
      };
      hooks = {
        config = {
          UserPromptSubmit = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = "echo '<system-reminder>MANDATORY: Use AskUserQuestion before proceeding.</system-reminder>'";
                }
              ];
            }
          ];
        };
      };
    };
  };
}
