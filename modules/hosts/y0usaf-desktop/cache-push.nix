{pkgs, ...}: {
  services.nix-daemon.settings.post-build-hook = toString (pkgs.writeShellScript "attic-cache-push" ''
    set -u
    [ -r /root/.config/attic/config.toml ] || exit 0
    [ -r /root/.config/attic/token ] || exit 0
    ${pkgs.attic-client}/bin/attic push cache $OUT_PATHS || echo "attic-cache-push: push failed" >&2
  '');
}
