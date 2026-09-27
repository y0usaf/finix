{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/Codex"
    ".config/codex"
    ".local/state/codex"
  ];
  system.activation.scripts.codexReasoningPolicy = {
    deps = ["users"];
    text = ''
      ${pkgs.util-linux}/bin/setpriv \
        --reuid "$(${pkgs.coreutils}/bin/id -u ${lib.escapeShellArg config.user.name})" \
        --regid "$(${pkgs.coreutils}/bin/id -g ${lib.escapeShellArg config.user.name})" \
        --clear-groups ${pkgs.python3}/bin/python3 ${./apply-reasoning-policy.py} \
        ${lib.escapeShellArg "${config.users.users.${config.user.name}.home}/.config/codex/config.toml"}
    '';
  };
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "codex" ''
      exec ${lib.getExe flakeInputs.codex-cli-nix.packages."${pkgs.stdenv.hostPlatform.system}".default} \
        --dangerously-bypass-approvals-and-sandbox \
        --config ${lib.escapeShellArg "developer_instructions=${builtins.toJSON (builtins.readFile ./system-prompt.md + "\n\n" + config.user.dev.prompts.ethics + "\n\n" + config.user.dev.prompts.noTests + "\n\n" + config.user.dev.prompts.noComments)}"} \
        "$@"
    '')
  ];
}
