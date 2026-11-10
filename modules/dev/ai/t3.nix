{
  config,
  lib,
  pkgs,
  inputPackages,
  ...
}: let
  home = config.user.homeDirectory;
  t3code = pkgs.t3code.override {enableCodex = false;};
  t3-tern = inputPackages.t3-tern.default;
in {
  environment.systemPackages = [t3code t3-tern];

  user.persist.directories = [".t3"];

  user.files.".config/tern/plugins/t3.path".text = "${t3-tern}/share/tern/plugins/t3\n";

  finix.persistence.homeServices = ["t3code"];

  finit.services.t3code = {
    description = "T3 Code server for ${config.user.name}";
    user = config.user.name;
    group = "users";
    command = "${t3code}/bin/t3 serve --no-browser --host 127.0.0.1 ${home}";
    environment =
      {HOME = home;}
      // lib.filterAttrs (_: value: value != null) {
        CLAUDE_CONFIG_DIR = config.environment.variables.CLAUDE_CONFIG_DIR or null;
        CODEX_HOME = config.environment.variables.CODEX_HOME or null;
      };
    path = [
      pkgs.coreutils
      "/run/current-system/sw"
      "/run/wrappers"
      "${home}/.nix-profile"
      "${home}/.local/state/nix/profile"
      "/nix/var/nix/profiles/default"
    ];
    conditions = ["net/lo/up"];
    respawn = true;
    log = true;
  };
}
