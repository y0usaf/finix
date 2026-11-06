{
  config,
  lib,
  pkgs,
  inputPackages,
  generators,
  ...
}: {
  user.persist.directories = [
    ".config/codex"
    ".local/state/codex"
  ];
  system.activation.scripts.codexReasoningPolicy = {
    deps = ["users"];
    text = ''
      ${pkgs.util-linux}/bin/setpriv \
        --reuid "$(${pkgs.coreutils}/bin/id -u ${lib.escapeShellArg config.user.name})" \
        --regid "$(${pkgs.coreutils}/bin/id -g ${lib.escapeShellArg config.user.name})" \
        --clear-groups ${pkgs.python3}/bin/python3 ${generators.sourceFile "apply-reasoning-policy.py" (generators.python.render (import ./apply-reasoning-policy.data.nix generators.python))} \
        ${lib.escapeShellArg "${config.users.users.${config.user.name}.home}/.config/codex/config.toml"}
    '';
  };
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "codex" ''
      exec ${lib.getExe inputPackages.codex-cli-nix.default} \
        --dangerously-bypass-approvals-and-sandbox \
        --config ${lib.escapeShellArg "developer_instructions=${builtins.toJSON config.user.dev.prompts.shared}"} \
        "$@"
    '')
  ];
}
