{
  config,
  lib,
  pkgs,
  flakeInputs,
  generators,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/codex"
    ".local/state/codex"
  ];
  system.activation.scripts.codexReasoningPolicy = {
    deps = ["users"];
    text = ''
      ${pkgs.util-linux}/bin/setpriv \
        --reuid "$(${pkgs.coreutils}/bin/id -u ${lib.escapeShellArg config.user.name})" \
        --regid "$(${pkgs.coreutils}/bin/id -g ${lib.escapeShellArg config.user.name})" \
        --clear-groups ${pkgs.python3}/bin/python3 ${generators.sourceFile "apply-reasoning-policy.py" (generators.pythonSource (import ./apply-reasoning-policy.data.nix))} \
        ${lib.escapeShellArg "${config.users.users.${config.user.name}.home}/.config/codex/config.toml"}
    '';
  };
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "codex" ''
      exec ${lib.getExe flakeInputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default} \
        --dangerously-bypass-approvals-and-sandbox \
        --config ${lib.escapeShellArg "developer_instructions=${builtins.toJSON config.user.dev.prompts.shared}"} \
        "$@"
    '')
  ];
}
