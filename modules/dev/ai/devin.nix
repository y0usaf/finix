{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.devin = {
    enable = lib.mkEnableOption "devin-cli package";
  };

  config = lib.mkIf config.user.dev.devin.enable {
    environment.systemPackages = [
      pkgs.devin-cli
    ];

    # Devin CLI reads always-on user-level rules from
    # ~/.config/devin/AGENTS.md (and AGENT.md) and loads them at the start of
    # every session, regardless of project. Source: official raw docs
    # https://docs.devin.ai/cli/extensibility/rules.md ("Global Rules") and
    # docs.devin.ai/cli/extensibility/configuration. Verified against the
    # installed CLI (devin 3000.4.25): `devin rules list` reports
    # "AGENTS [Standard] always-on" and `devin rules show AGENTS` reports
    # Path ~/.config/devin/AGENTS.md, Activation always-on. Deploying
    # AGENTS.md there supplies the shared no-test policy; the package-only
    # module had no config file before.
    #
    # config.json is merge-deployed, not symlinked: the CLI mutates it at
    # runtime (permissions.allow grants, org_id), so merge keeps it writable
    # and re-applies our keys on every switch. `attribution = false` drops the
    # "Generated with [Devin]" line and the Co-Authored-By: Devin trailer from
    # commits and PRs (docs.devin.ai/cli/reference/configuration/config-file).
    # The permission mode has no config key — it is per-session state — so
    # DEVIN_PERMISSION_MODE pins every launch to "dangerous" (the flag's
    # canonical name for yolo/bypass; see `devin --help`).
    manzil.users."${config.user.name}".files = {
      ".config/devin/AGENTS.md".text =
        config.user.dev.prompts.ethics + "\n\n" + config.user.dev.prompts.noTests;
      ".config/devin/config.json" = {
        type = "merge";
        format = "json";
        clobber = true;
        value = {
          attribution = false;
        };
      };
    };

    environment.variables.DEVIN_PERMISSION_MODE = "dangerous";
  };
}
