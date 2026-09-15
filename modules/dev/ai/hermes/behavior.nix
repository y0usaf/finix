# Reproduce the default-profile behavioral baseline without replacing runtime data.
{ config, lib, pkgs, flakeInputs, ... }:
let
  user = config.user.name;
  home = config.users.users.${user}.home;
  settings = builtins.fromJSON (builtins.readFile ./behavior-settings.json);
  applyPolicy = pkgs.writeShellScript "hermes-apply-behavior-policy" ''
    set -eu
    export HOME=${lib.escapeShellArg home}
    export HERMES_HOME=${lib.escapeShellArg "${home}/.hermes"}
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (key: value:
      "${config.user.dev.ai.hermes.packages.hermesFull}/bin/hermes config set --force ${lib.escapeShellArg key} ${lib.escapeShellArg (if builtins.isString value then value else builtins.toJSON value)}"
    ) settings)}
  '';
in {
  # SOUL.md is Hermes's system prompt. Compose the Finix-owned charter with the
  # shared no-test-authoring policy so config.user.dev.prompts.noTests stays the
  # single source; SOUL.md itself is left as written.
  manzil.users.${user}.files.".hermes/SOUL.md" = {
    text = builtins.readFile ./SOUL.md + "\n" + config.user.dev.prompts.noTests + "\n";
    clobber = true;
  };
  system.activation.scripts.hermesBehaviorPolicy = {
    deps = [ "users" ];
    text = ''
      # Match Manzil's Finix uid/gid drop: Finix has no runuser PAM service.
      ${pkgs.util-linux}/bin/setpriv \
        --reuid "$(${pkgs.coreutils}/bin/id -u ${lib.escapeShellArg user})" \
        --regid "$(${pkgs.coreutils}/bin/id -g ${lib.escapeShellArg user})" \
        --clear-groups ${applyPolicy}
    '';
  };
}
