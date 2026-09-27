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
    terminal = lib.mkOption {
      type = lib.types.str;
      default = "foot";
      description = "Default terminal emulator";
    };
    launcher = lib.mkOption {
      type = lib.types.str;
      default = "monstar --app-id=launcher -e ~/.config/scripts/tui-launcher.sh";
      description = "Default application launcher";
    };
  };

  config.environment.variables = {
    TERMINAL = config.user.defaults.terminal;
    BROWSER = config.user.defaults.browser;
    EDITOR = "nvim";
  };
}
