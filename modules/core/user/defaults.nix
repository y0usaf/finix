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

  # Exported here, not from .bashrc: /etc/profile.d reaches the compositor and
  # everything it spawns, so tui-launcher sees TERMINAL regardless of whether a
  # shell started the session at all. An rc-file export would only cover
  # interactive shells, which is why finix sessions had to re-export TERMINAL by
  # hand in hosts/y0usaf-desktop/finix/session.nix.
  # (sessionVariables re-homed to variables for the compat remap.)
  config.environment.variables = {
    TERMINAL = config.user.defaults.terminal;
    BROWSER = config.user.defaults.browser;
    EDITOR = config.user.defaults.editor;
  };
}
