# Single-Limine boot driver for the finix DESKTOP (replaces the ESP island
# on this host; the server keeps modules/finix/esp-island.nix — headless, its BootNext
# deadman ceremony still earns its keep there).
#
# Rationale: Limine's job is multi-OS menus. The island ran a SECOND Limine
# (\EFI\finix\BOOTX64.EFI, chainloaded from NixOS's) purely to own a config
# file — double bootloader, and the reason config-only deploys silently
# reverted on reboot (deploy activates runtime; the island's pinned slot is
# what actually booted).
#
# This driver manages a marked section inside the EXISTING NixOS limine.conf
# (/boot/limine/limine.conf, the file NixOS's limine module regenerates):
#
#   # FINIX-MANAGED-BEGIN
#   /Finix <slot>
#     protocol: linux ... (kernel+initrd+cmdline staged per slot)
#   /Finix <slot> (previous)
#   # FINIX-MANAGED-END
#
# placed before the NixOS generations so default_entry: 1 = current finix.
# NixOS generations below stay as the rescue path (same Limine, no
# chainload). Kernels/slots state live at /boot/EFI/finix/ (storage only —
# the NixOS limine module manages /boot/limine exclusively and would prune
# unknown kernels there; it never touches /boot/EFI/finix).
#
# Ownership ladder: section-writer (default, coexists with NixOS rebuilds —
# a rebuild wipes the managed section; re-run `install`) → `adopt` (take over
# BOOTX64.EFI from pkgs.limine; every render then re-enrolls + re-signs) →
# `retire-nixos` (strip the NixOS generations block; the conf becomes ours).
#
# Safety model (vs the island's BootOrder/BootNext dance — desktop has
# physical access, the Limine menu IS the fallback):
#   install   stage slot, point managed section + default_entry at it
#   rollback  flip current/previous, re-render
#   status    show state
#   adopt     one-time: own the Limine binary too (pkgs.limine), create the
#             'Limine' EFI entry if missing; every render then re-enrolls
#             the config hash + re-signs (sbctl)
#   retire-nixos  final: strip NixOS generations from limine.conf entirely
#   cleanup-island  one-time: delete the Boot0005 "Finix" EFI entry and the
#                   island's BOOTX64.EFI + limine.conf (kernels/slots kept)
{
  lib,
  pkgs,
}: {
  # mkLimineEntries {name, system, ucodeImg}
  mkLimineEntries = {
    name,
    system,
    ucodeImg,
  }: let
    script = pkgs.writeShellScript "finix-limine-entries" ''
      set -euo pipefail
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux pkgs.gnugrep pkgs.gnused pkgs.gawk pkgs.efibootmgr pkgs.diffutils pkgs.limine pkgs.sbctl]}

      esp=/boot
      conf=$esp/limine/limine.conf
      state_dir=$esp/EFI/finix          # storage only; no second Limine here
      state=$state_dir/slots
      BEGIN='# FINIX-MANAGED-BEGIN'
      END='# FINIX-MANAGED-END'
      limine_efi=$esp/EFI/limine/BOOTX64.EFI

      # Limine verifies the loaded conf against the blake2b hash enrolled in
      # BOOTX64.EFI (NixOS enrolls because secureBoot.enable → enrollConfig;
      # verification happens with SB OFF in firmware too — the 2026-07
      # hash-mismatch incident). Always start from the PRISTINE binary:
      # enrollment modifies it in place and sbctl refuses to re-sign a
      # mangled prior signature ("incorrect digest"). Enroll before sign,
      # atomic mv last — the exact flow of NixOS's limine module. Keys
      # persist at /var/lib/sbctl (impermanence allowlist, finix replays).
      enroll_sign() {
        cp ${pkgs.limine}/share/limine/BOOTX64.EFI "$limine_efi.tmp"
        limine enroll-config "$limine_efi.tmp" "$(b2sum "$conf" | cut -d' ' -f1)"
        if [ -d /var/lib/sbctl/keys ]; then
          sbctl sign "$limine_efi.tmp" >/dev/null || die "sbctl sign failed"
        else
          echo "warn: /var/lib/sbctl/keys absent — left unsigned (SB off in firmware)" >&2
        fi
        mv "$limine_efi.tmp" "$limine_efi"
      }

      die() { echo "ERROR: $*" >&2; exit 1; }

      [ "$(id -u)" = 0 ] || die "must run as root"
      mountpoint -q "$esp" || die "$esp is not a mountpoint"
      [ -f "$conf" ] || die "no limine.conf at $conf (NixOS limine module manages it)"

      # finix mounts no efivarfs by default (kernel support only); the island
      # tooling mounts it on demand — same here. Quietly absent on non-EFI.
      if [ -d /sys/firmware/efi ] && ! mountpoint -q /sys/firmware/efi/efivars 2>/dev/null; then
        mount -t efivarfs efivarfs /sys/firmware/efi/efivars 2>/dev/null || true
      fi
      efi_vars_ok=0
      mountpoint -q /sys/firmware/efi/efivars 2>/dev/null && efi_vars_ok=1

      copy_changed() { # src dst - vfat-friendly, skip if identical
        if ! cmp -s "$1" "$2" 2>/dev/null; then
          cp "$1" "$2.tmp" && mv "$2.tmp" "$2"
        fi
      }

      write_file() { printf '%s\n' "$2" > "$1.tmp" && mv "$1.tmp" "$1"; }

      read_state() {
        cur=""; prev=""
        if [ -f "$state" ]; then
          cur=$(sed -n 's/^current=//p' "$state")
          prev=$(sed -n 's/^previous=//p' "$state")
        fi
      }

      emit_slot() { # slot title-suffix
        printf '/Finix %s%s\n' "$1" "$2"
        printf '  protocol: linux\n'
        printf '  kernel_path: boot():/EFI/finix/kernels/%s/kernel\n' "$1"
        printf '  cmdline: %s\n' "$(cat "$state_dir/kernels/$1/cmdline")"
        printf '  module_path: boot():/EFI/finix/kernels/%s/initrd\n' "$1"
      }

      # Rebuild the marked section inside NixOS's limine.conf: drop any old
      # block, insert the fresh one before the NixOS generations so the
      # current finix slot is entry 1, and point default_entry at it.
      render_conf() { # cur prev
        local block
        block=$BEGIN$'\n'$(emit_slot "$1" "")
        if [ -n "$2" ] && [ -f "$state_dir/kernels/$2/cmdline" ]; then
          block=$block$'\n\n'$(emit_slot "$2" " (previous)")
        fi
        # Pinned parachute slot (see NOTES.md): always LAST in the managed
        # block, so default_entry 1 stays the current slot.
        if [ -f "$state_dir/kernels/golden/cmdline" ]; then
          block=$block$'\n\n'$(emit_slot golden "")
        fi
        block=$block$'\n'$END
        awk -v block="$block" -v begin="$BEGIN" -v end="$END" '
          $0 == begin { skip = 1 }
          skip { if ($0 == end) skip = 0; next }
          !inserted && /^# NixOS boot entries start here/ {
            print block; print ""; inserted = 1
          }
          { print }
        ' "$conf" > "$conf.tmp"
        # No NixOS marker (post-retire-nixos the conf is solely ours): the
        # finix block belongs on TOP, not appended at the end.
        if ! grep -qF "$BEGIN" "$conf.tmp"; then
          { printf '%s\n\n' "$block"; cat "$conf.tmp"; } > "$conf.tmp2" \
            && mv "$conf.tmp2" "$conf.tmp"
        fi
        # default_entry -> 1 (the current finix slot sits first)
        sed -i 's/^default_entry:.*/default_entry: 1/' "$conf.tmp"
        mv "$conf.tmp" "$conf"
        enroll_sign
      }

      prune_slots() { # cur prev
        local d r s
        # 'golden' = operator-pinned parachute slot (see NOTES.md); never pruned.
        for d in "$state_dir/kernels"/*/; do
          [ -d "$d" ] || continue
          s=$(basename "$d")
          [ "$s" = golden ] && continue
          [ "$s" = "$1" ] || [ "$s" = "$2" ] || rm -rf "$d"
        done
        for r in /nix/var/nix/gcroots/finix-esp-*; do
          [ -e "$r" ] || continue
          s=''${r##*finix-esp-}
          [ "$s" = golden ] && continue
          [ "$s" = "$1" ] || [ "$s" = "$2" ] || rm -f "$r"
        done
      }

      do_install() {
        local system cmdline slot
        system=$1 cmdline=$2
        [ -e "$system/kernel" ] && [ -e "$system/initrd" ] || die "$system lacks kernel/initrd"
        slot=$(basename "$system" | cut -c1-8)
        mkdir -p "$state_dir/kernels/$slot"

        copy_changed "$system/kernel" "$state_dir/kernels/$slot/kernel"
        # Early microcode prepend — direct firmware boots must not run the
        # raw BIOS ucode (island incident #2: early hang + hard freeze).
        tmp_initrd=$(mktemp /tmp/finix-limine-initrd.XXXXXX)
        cat ${ucodeImg} "$system/initrd" > "$tmp_initrd"
        copy_changed "$tmp_initrd" "$state_dir/kernels/$slot/initrd"
        rm -f "$tmp_initrd"
        write_file "$state_dir/kernels/$slot/cmdline" "$cmdline"
        write_file "$state_dir/kernels/$slot/system" "$system"

        # The booted slot execs init out of /nix/store: root its closure.
        "$system/sw/bin/nix-store" --realise "$system" \
          --add-root "/nix/var/nix/gcroots/finix-esp-$slot" >/dev/null

        read_state
        if [ "$cur" != "$slot" ]; then
          prev=$cur
          cur=$slot
        fi
        printf 'current=%s\nprevious=%s\n' "$cur" "$prev" > "$state.tmp" && mv "$state.tmp" "$state"

        render_conf "$cur" "$prev"
        prune_slots "$cur" "$prev"
        sync
        echo "==> slot $cur is limine.conf entry 1 (default); previous: ''${prev:-none}"
        echo "==> reboot boots it directly — previous + golden slots remain in the menu as rescue"
      }

      do_rollback() {
        read_state
        [ -n "$prev" ] || die "no previous slot recorded"
        [ -f "$state_dir/kernels/$prev/cmdline" ] || die "previous slot $prev missing from ESP"
        printf 'current=%s\nprevious=%s\n' "$prev" "$cur" > "$state.tmp" && mv "$state.tmp" "$state"
        render_conf "$prev" "$cur"
        sync
        echo "==> default now $prev (was $cur); reboot to take effect"
      }

      do_cleanup_island() {
        # One-time retirement of the second Limine. Keeps kernels/slots
        # (still referenced by the managed section).
        local n
        for n in $(efibootmgr | sed -n 's/^Boot\([0-9A-F]\{4\}\)[^ ]* Finix\t.*/\1/p'); do
          echo "==> deleting EFI entry Boot$n (Finix island)"
          efibootmgr -q -b "$n" -B
        done
        rm -f "$state_dir/BOOTX64.EFI" "$state_dir/limine.conf" \
              "$state_dir/limine.conf.tmp" "$state_dir/BOOTX64.EFI.tmp"
        # Strip the legacy chainload entry (NixOS-side extraEntries from
        # hosts/y0usaf-desktop/finix-boot.nix, now retired — it would point
        # at the BOOTX64.EFI just deleted). Entry runs to the next /-entry
        # or EOF (extraEntries append at the end).
        awk '
          /^\/Finix \(island\)$/ { skip = 1; next }
          skip && /^\// { skip = 0 }
          !skip { print }
        ' "$conf" > "$conf.tmp" && mv "$conf.tmp" "$conf"
        echo "==> island bootloader + chainload entry removed; single Limine at \\efi\\limine"
      }

      do_adopt() {
        # One-time takeover of the Limine binary from the NixOS limine module.
        # Same path → the existing 'Limine' EFI entry stays valid; every
        # render from then on keeps the conf hash enrolled + binary signed.
        read_state
        [ -n "$cur" ] || die "no finix slot staged — run install first"

        if [ "$efi_vars_ok" = 1 ]; then
          if ! efibootmgr | grep -qi 'limine'; then
            local src disk part
            src=$(findmnt -n -o SOURCE "$esp") || die "cannot resolve $esp source device"
            disk=/dev/$(lsblk -n -o PKNAME "$src")
            part=$(cat "/sys/class/block/$(basename "$src")/partition")
            efibootmgr -q -c -d "$disk" -p "$part" -L Limine -l '\EFI\limine\BOOTX64.EFI'
            echo "==> created EFI entry 'Limine' ($disk part $part)"
          fi
        else
          echo "==> no efivars visible (agent namespace?) — skipping EFI entry check;"
          echo "    the existing 'Limine' entry on the host keeps pointing at this binary"
        fi
        render_conf "$cur" "$prev"
        sync
        echo "==> /boot/limine is finix-owned (binary from pkgs.limine, conf enrolled+signed)"
        echo "==> NixOS generations kept as rescue — purge with: finix-desktop-boot local retire-nixos"
      }

      do_retire_nixos() {
        # Final NixOS purge, boot-menu side: strip the generations block; the
        # finix managed section + everything else stays. Store-side purge
        # (profile generations + gc) is manual — see modules/finix/NOTES.md.
        grep -qF "$BEGIN" "$conf" || die "no finix managed section in $conf — run install first"
        awk '
          /^# NixOS boot entries start here/ { skip = 1; next }
          skip && /^# NixOS boot entries end here/ { skip = 0; next }
          !skip { print }
        ' "$conf" > "$conf.tmp" && mv "$conf.tmp" "$conf"
        enroll_sign
        sync
        echo "==> NixOS generations removed from limine.conf (re-enrolled+signed)"
        echo "==> next: delete system profile generations + gc, per NOTES.md"
      }

      do_status() {
        echo "== slots =="
        if [ -f "$state" ]; then
          cat "$state"
          ls -1 "$state_dir/kernels" 2>/dev/null | sed 's/^/slot: /'
        else
          echo "not installed"
        fi
        echo
        echo "== managed section in $conf =="
        awk -v begin="$BEGIN" -v end="$END" '
          $0 == begin { show = 1 }
          show { print }
          $0 == end { show = 0 }
        ' "$conf" 2>/dev/null || true
        grep '^default_entry:' "$conf" || true
        echo
        echo "== EFI (leftover island entries?) =="
        efibootmgr | grep -E '^(BootCurrent|BootOrder)|Limine|Finix' || true
      }

      action=''${1:-status}
      shift || true
      case "$action" in
        install) do_install "''${1:?system path required}" "''${2:?cmdline required}" ;;
        rollback) do_rollback ;;
        cleanup-island) do_cleanup_island ;;
        adopt) do_adopt ;;
        retire-nixos) do_retire_nixos ;;
        status) do_status ;;
        *) die "unknown action: $action" ;;
      esac
    '';
  in {
    # Local-only driver (desktop drives its own ESP under sudo).
    bootDriverScript = pkgs.writeShellScriptBin name ''
      set -euo pipefail

      host="''${1:-local}"
      action="''${2:-status}"
      [ "$host" = local ] || { echo "${name}: desktop driver is local-only (server uses finix-server-boot)" >&2; exit 2; }
      case "$action" in
        status|install|rollback|cleanup-island|adopt|retire-nixos) ;;
        *)
          echo "usage: ${name} [local] [status|install|rollback|cleanup-island|adopt|retire-nixos]" >&2
          exit 2
          ;;
      esac

      system_path='${system}'

      if [ "$action" = install ]; then
        bootjson="$system_path/boot.json"
        init="$(${pkgs.jq}/bin/jq -r '.["org.nixos.bootspec.v1"].init' "$bootjson")"
        kernel_params="$(${pkgs.jq}/bin/jq -r '.["org.nixos.bootspec.v1"].kernelParams | join(" ")' "$bootjson")"
        exec sudo ${script} install "$system_path" "init=$init $kernel_params"
      fi
      exec sudo ${script} "$action"
    '';
  };
}
