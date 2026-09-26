{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.claude-code.enable = lib.mkEnableOption "Claude Code";

  config = lib.mkIf config.user.dev.claude-code.enable {
    environment.etc."claude-code/managed-settings.json".text = builtins.toJSON {
      model = "claude-opus-5-5";
      effortLevel = "xhigh";
      permissions.defaultMode = "bypassPermissions";
      skipDangerousModePermissionPrompt = true;
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "claude" ''
        exec ${lib.getExe pkgs.claude-code} \
          --effort max \
          --append-system-prompt ${lib.escapeShellArg (config.user.dev.prompts.ethics + "\n\n" + config.user.dev.prompts.noTests + "\n\n" + config.user.dev.prompts.noComments)} \
          "$@"
      '')
    ];
  };
}
