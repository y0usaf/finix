{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.claude-code = {
    enable = lib.mkEnableOption "Claude Code development tools";
  };

  config = lib.mkIf config.user.dev.claude-code.enable {
    environment.systemPackages = [
      pkgs.claude-code
    ];
  };
}
