{
  config,
  lib,
  ...
}: {
  options.user.defaults = {
    browser = lib.mkOption {
      type = lib.types.str;
      default = "librewolf";
      description = "Default web browser";
    };
    editor = lib.mkOption {
      type = lib.types.str;
      default = "nvim";
      description = "Default text editor";
    };
    terminal = lib.mkOption {
      type = lib.types.str;
      default = "foot";
      description = "Default terminal emulator";
    };
  };

  config.environment.variables = {
    TERMINAL = config.user.defaults.terminal;
    BROWSER = config.user.defaults.browser;
    EDITOR = config.user.defaults.editor;
  };
}
