{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.etc."claude-code/managed-settings.json".text = builtins.toJSON {
    effortLevel = "xhigh";
    permissions.defaultMode = "bypassPermissions";
    skipDangerousModePermissionPrompt = true;
  };

  finix.persistence.allowlist.users.${config.user.name}.directories = [".config/claude"];

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "claude" ''
      exec ${lib.getExe pkgs.claude-code} \
        --effort max \
        --append-system-prompt ${lib.escapeShellArg config.user.dev.prompts.shared} \
        "$@"
    '')
  ];
}
