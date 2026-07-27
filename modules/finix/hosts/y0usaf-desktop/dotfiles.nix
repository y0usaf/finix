# Dotfile parity with NixOS: manzil owns ~/.config/* & friends as symlinks
# into /nix/store, materialized by a NixOS *activation script* that finix
# never runs. The links were previously refreshed on every NixOS boot; after
# the 2026-07-28 purge runbook (delete NixOS generations + nix store gc)
# every link target lost its GC root and all ~12k manzil symlinks in $HOME
# went dangling — nushell rc, foot.ini, tomoe init.lua/shell, gtk, git, …
#
# Fix: replay the SAME evaluated manzil manifest (via the packages-bridge
# NixOS eval) as a finit task on every boot. Dotfiles track the deployed
# finix generation; the manifest — and therefore every source it points at —
# rides the finix topLevel closure, so `nix store gc` can never collect a
# live link target again. /var/lib/manzil (linker state) is deliberately
# NOT persisted: the linker replays the full manifest every boot, so stale
# state would only save diff work.
#
# Two deltas from the NixOS activation snippet:
#   - runuser → setpriv: finix PAM has no runuser service, so the uid switch
#     would be denied. setpriv does the same drop with zero PAM. uid 1001 /
#     gid 100 (users) match both universes (uid pinned in persistent.nix).
#   - ordering: the writes must land AFTER persist-user-binds — several
#     targets (~/.config/nushell, ~/.config/ekko) are /persist binds, and
#     writing beforehand would end up on the @home dirs the binds cover.
{
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  nixosCfg = flakeInputs.self.nixosConfigurations.y0usaf-desktop-nixos.config;

  # The upstream snippet renders util-linux runuser(8); swap the uid-switch
  # mechanism only, keep everything else (flock, state install on success)
  # verbatim. The util-linux store path stays in the text, so the script's
  # closure keeps: linker, manifest, and — transitively — every dotfile
  # source the manifest references.
  manzilLink =
    lib.replaceStrings ["bin/runuser -u y0usaf -- "]
    ["bin/setpriv --reuid=1001 --regid=100 --clear-groups "]
    nixosCfg.system.activationScripts.manzil.text;
in {
  finit.tasks.manzil-link = {
    description = "materialize manzil dotfiles (replay the NixOS manifest)";
    command = "${pkgs.writeShellScript "manzil-link" ''
      set -u
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux]}

      # persist-user-binds must finish first: manzil writes into dirs that
      # are bind-mounted from /persist (e.g. ~/.config/nushell). Writing
      # before the bind would land on the covered @home dir, invisible.
      for _ in $(seq 1 120); do
        mountpoint -q /home/y0usaf/.config/nushell && break
        sleep 1
      done
      mountpoint -q /home/y0usaf/.config/nushell || { echo "manzil-link: user binds never mounted" >&2; exit 1; }

      ${manzilLink}
    ''}";
    log = true;
  };
}
