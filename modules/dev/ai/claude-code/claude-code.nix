{ config, lib, pkgs, ... }: {
  options.user.dev.claude-code.enable = lib.mkEnableOption "Claude Code";

  config = lib.mkIf config.user.dev.claude-code.enable {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "claude" ''
        exec ${lib.getExe pkgs.claude-code} --dangerously-skip-permissions "$@"
      '')
    ];
  };
}
