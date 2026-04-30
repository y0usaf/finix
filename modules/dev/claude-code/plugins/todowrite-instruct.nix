_: {
  config.user.dev.claude-code.plugins = {
    todowrite-instruct = {
      name = "todowrite-instruct";
      version = "1.0.0";
      description = "Reminders to use TodoWrite for task tracking";
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
                  command = "echo '<system-reminder>MANDATORY: Use TaskCreate before proceeding.</system-reminder>'";
                }
              ];
            }
          ];
        };
      };
    };
  };
}
