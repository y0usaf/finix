{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  # Codex's task-specific guidance plus the shared no-test-authoring policy.
  # developer_instructions is codex's supported extra system guidance channel.
  developerInstructions =
    builtins.readFile ./system-prompt.md + "\n\n" + config.user.dev.prompts.noTests;
in {
  options.user.dev.codex.enable = lib.mkEnableOption "Codex CLI";

  config = lib.mkIf config.user.dev.codex.enable {
    # Reconcile the shared CLI/desktop config without replacing runtime settings.
    system.activation.scripts.codexReasoningPolicy = {
      deps = [ "users" ];
      text = let
        user = lib.escapeShellArg config.user.name;
        home = config.users.users.${config.user.name}.home;
      in ''
        ${pkgs.util-linux}/bin/setpriv \
          --reuid "$(${pkgs.coreutils}/bin/id -u ${user})" \
          --regid "$(${pkgs.coreutils}/bin/id -g ${user})" \
          --clear-groups ${pkgs.python3}/bin/python3 ${./apply-reasoning-policy.py} \
          ${lib.escapeShellArg "${home}/.config/codex/config.toml"}
      '';
    };
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "codex" ''
        exec ${lib.getExe flakeInputs.codex-cli-nix.packages."${pkgs.stdenv.hostPlatform.system}".default} \
          --dangerously-bypass-approvals-and-sandbox \
          --config ${lib.escapeShellArg "developer_instructions=${builtins.toJSON developerInstructions}"} \
          "$@"
      '')
    ];
  };
}
