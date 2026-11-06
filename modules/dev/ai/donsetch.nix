{
  lib,
  pkgs,
  inputPackages,
  ...
}: let
  inherit (inputPackages.pi-donsetch) donsetch;
in {
  user.persist.directories = [".cache/donsetch"];

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
