{
  config,
  lib,
  ...
}: {
  options.user.dev.claude-code = {
    enable = lib.mkEnableOption "Claude Code development tools";

    model = lib.mkOption {
      type = lib.types.str;
      default = "claude-haiku-4-5";
      description = "Claude model to use";
    };
  };

  config = lib.mkIf config.user.dev.claude-code.enable {
    environment.systemPackages = [];
  };
}
