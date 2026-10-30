{
  config,
  lib,
  pkgs,
  ...
}: let
  shell = ''
    ## Shell

    In the Bash tool, `grep` and `find` are Claude Code's own ugrep and bfs.
    grep skips binary files and, when recursive, gitignored ones, and can
    reject complex regexes such as large bounded repeats.
    `command grep` and `command find` run GNU grep and findutils.'';
in {
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
        --append-system-prompt ${lib.escapeShellArg (config.user.dev.prompts.shared + "\n\n" + shell)} \
        "$@"
    '')
  ];
}
