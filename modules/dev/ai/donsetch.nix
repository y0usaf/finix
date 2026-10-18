{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  donsetch = flakeInputs.pi-donsetch.packages.${pkgs.stdenv.hostPlatform.system}.donsetch;
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".cache/donsetch"
  ];

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "donsetch-login" ''
      set -eu
      profile="''${XDG_CACHE_HOME:-$HOME/.cache}/donsetch/ghost-profile"
      ${lib.getExe donsetch} stop || true
      mkdir -p "$profile"
      exec ${lib.getExe pkgs.ungoogled-chromium} \
        --user-data-dir="$profile" \
        --no-first-run \
        --no-default-browser-check \
        "$@"
    '')
  ];
}
