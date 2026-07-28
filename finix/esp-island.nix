# ESP island + BootNext boot driver (stage 3 tooling; see NOTES.md).
# Generalized from the server-only original: mkIsland instantiates the pair
# (remote island script + driver) per host. Server keeps intel ucode + ssh
# operation; the desktop drives its own ESP locally (host = "local").
{
  lib,
  pkgs,
}: {
  # mkIsland {name, system, ucodeImg, defaultHost}
  #   name        driver binary name (e.g. finix-server-boot)
  #   system      the persistent config's system.topLevel
  #   ucodeImg    early-microcode cpio prepended to every staged initrd
  #               (intel-ucode.img / amd-ucode.img — incident #2: direct
  #               firmware boots MUST NOT run the raw BIOS microcode)
  #   defaultHost ssh target when none given, or "local" to run the island
  #               script on this machine under sudo (desktop drives itself)
  mkIsland = {
    defaultHost,
    name,
    system,
    ucodeImg,
  }: rec {
    # ── Stage 3: ESP island + BootNext (bootloader takeover without hands) ──
    #
    # Root half; runs on the target box under either OS. Manages a fully
    # self-contained Finix boot island on the ESP:
    #
    #   /boot/EFI/finix/BOOTX64.EFI       own copy of Limine (app-adjacent conf)
    #   /boot/EFI/finix/limine.conf       island config, default_entry: 1
    #   /boot/EFI/finix/kernels/<slot>/   kernel+initrd+cmdline per generation
    #   /boot/EFI/finix/slots             current=/previous= slot state
    #
    # plus a "Finix" EFI boot entry pointing at the island. It never touches
    # NixOS's /boot/limine + \efi\limine (and the NixOS installer never prunes
    # \EFI\finix), so the frozen NixOS config and this tool cannot fight.
    #
    # Safety model (see NOTES.md "Stage 3 mechanism"):
    #   install  stage new slot as island default; force BootOrder NixOS-first
    #            (opens a test window - an untested slot is never the cold-boot
    #            default)
    #   oneshot  BootNext=Finix + reboot: boots the island exactly once; any
    #            crash/hang/panic falls home to NixOS via BootOrder
    #   promote  BootOrder Finix-first; refused unless this boot IS the island
    #   demote   manual safety lever back to NixOS-first
    #   rollback island default -> previous slot
    espIslandScript = pkgs.writeShellScript "finix-esp-island" ''
      set -euo pipefail
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux pkgs.gnugrep pkgs.gnused pkgs.efibootmgr pkgs.diffutils]}

      esp=/boot
      island=$esp/EFI/finix
      conf=$island/limine.conf
      state=$island/slots
      label=Finix

      die() { echo "ERROR: $*" >&2; exit 1; }

      [ "$(id -u)" = 0 ] || die "must run as root"
      mountpoint -q /sys/firmware/efi/efivars \
        || mount -t efivarfs efivarfs /sys/firmware/efi/efivars \
        || die "no EFI variable support"
      mountpoint -q "$esp" || die "$esp is not a mountpoint"
      # Fall-home verification: the island's safety model needs a working
      # non-island boot path. Missing rescue used to die here; post-purge the
      # NixOS limine is gone from the ESP, so warn loudly instead. Operators
      # who require the fall-home gate pass --require-fallhome to install.
      require_fallhome=0
      verify_fallhome() {
        local ok=1 rescue_path
        # Every non-Finix EFI entry must point at a binary that exists on the ESP.
        rescue_path=$(sed -n 's|^  path: boot():/\(.*\)$|\1|p' "$conf" 2>/dev/null | head -n1)
        if [ -n "$rescue_path" ] && [ ! -f "$esp/$rescue_path" ]; then
          echo "WARN: limine rescue entry target missing: $esp/$rescue_path" >&2
          ok=0
        fi
        # The UEFI fallback loader must not be the island itself (identical
        # bytes = both boot paths land on the same config = no fall-home).
        if [ -f "$esp/EFI/BOOT/BOOTX64.EFI" ] && cmp -s "$esp/EFI/BOOT/BOOTX64.EFI" "$island/BOOTX64.EFI" 2>/dev/null; then
          echo "WARN: fallback EFI/BOOT/BOOTX64.EFI is the island limine - no independent fall-home" >&2
          ok=0
        fi
        if [ "$ok" != 1 ] && [ "$require_fallhome" = 1 ]; then
          die "fall-home verification failed"
        fi
        [ "$ok" = 1 ]
      }

      entry_num() { # exact label -> XXXX (first match) or empty
        efibootmgr | sed -n "s/^Boot\([0-9A-F]\{4\}\)[^ ]* $1\t.*/\1/p" | head -n1
      }
      boot_order() { efibootmgr | sed -n 's/^BootOrder: //p'; }
      order_without() { boot_order | tr ',' '\n' | grep -vx "$1" | paste -sd, - || true; }

      demote() { # Finix last: load failure or fresh NVRAM falls to NixOS loaders
        local num rest
        num=$(entry_num "$label") || true
        [ -n "$num" ] || return 0
        rest=$(order_without "$num")
        efibootmgr -q -o "''${rest:+$rest,}$num"
      }

      copy_changed() { # src dst - vfat-friendly, skip if identical
        if ! cmp -s "$1" "$2" 2>/dev/null; then
          cp "$1" "$2.tmp" && mv "$2.tmp" "$2"
        fi
      }

      write_file() { # dst content
        printf '%s\n' "$2" > "$1.tmp" && mv "$1.tmp" "$1"
      }

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
        printf '  cmdline: %s\n' "$(cat "$island/kernels/$1/cmdline")"
        printf '  module_path: boot():/EFI/finix/kernels/%s/initrd\n' "$1"
      }

      render_conf() { # cur prev
        {
          printf 'timeout: 3\ndefault_entry: 1\n\n'
          emit_slot "$1" ""
          if [ -n "$2" ] && [ -f "$island/kernels/$2/cmdline" ]; then
            printf '\n'
            emit_slot "$2" " (previous)"
          fi
          # Only advertise the rescue entry when its target actually exists;
          # a dead menu entry is worse than none (incident #3).
          if [ -f "$esp/efi/limine/BOOTX64.EFI" ]; then
            printf '\n/NixOS rescue (Limine)\n  protocol: efi\n  path: boot():/efi/limine/BOOTX64.EFI\n'
          fi
        } > "$conf.tmp" || die "failed to render $conf.tmp"
        # Sanity before swap: every kernel/module path in the conf must exist
        # on the ESP, and the conf must contain at least one Finix entry.
        local p
        for p in $(sed -n 's|^  \(kernel\|module\)_path: boot():/\(.*\)$|\2|p' "$conf.tmp"); do
          [ -f "$esp/$p" ] || die "rendered conf references missing ESP file: $p"
        done
        grep -q '^/Finix ' "$conf.tmp" || die "rendered conf has no Finix entry"
        [ -f "$conf" ] && cp "$conf" "$conf.bak"
        mv "$conf.tmp" "$conf"
      }

      prune_slots() { # cur prev
        local d r s
        for d in "$island/kernels"/*/; do
          [ -d "$d" ] || continue
          s=$(basename "$d")
          [ "$s" = "$1" ] || [ "$s" = "$2" ] || rm -rf "$d"
        done
        for r in /nix/var/nix/gcroots/finix-esp-*; do
          [ -e "$r" ] || continue
          s=''${r##*finix-esp-}
          [ "$s" = "$1" ] || [ "$s" = "$2" ] || rm -f "$r"
        done
      }

      clean_stale() {
        # April-era unmanaged leftovers: lowercase-'finix' EFI entries pointing
        # at an orphaned hand-built UKI, plus the UKI file itself.
        local n
        for n in $(efibootmgr | sed -n 's/^Boot\([0-9A-F]\{4\}\)[^ ]* finix\t.*/\1/p'); do
          echo "==> deleting stale EFI entry Boot$n (finix)"
          efibootmgr -q -b "$n" -B
        done
        if [ -f "$island/finix.efi" ]; then
          echo "==> removing stale $island/finix.efi (unmanaged UKI)"
          rm -f "$island/finix.efi"
        fi
      }

      ensure_entry() {
        local num order esp_src esp_name esp_disk esp_part
        num=$(entry_num "$label") || true
        [ -n "$num" ] && return 0
        esp_src=$(findmnt -no SOURCE "$esp")
        esp_name=$(basename "$esp_src")
        esp_part=$(cat "/sys/class/block/$esp_name/partition")
        esp_disk=/dev/$(basename "$(readlink -f "/sys/class/block/$esp_name/..")")
        order=$(boot_order)
        efibootmgr -q -c -d "$esp_disk" -p "$esp_part" -L "$label" -l '\EFI\finix\BOOTX64.EFI'
        num=$(entry_num "$label")
        [ -n "$num" ] || die "failed to create $label EFI entry"
        # -c prepends to BootOrder; keep NixOS loaders first until promote.
        efibootmgr -q -o "''${order:+$order,}$num"
        echo "==> created EFI entry Boot$num ($label), appended last in BootOrder"
      }

      reboot_now() {
        sync
        if [ -d /run/systemd/system ]; then
          exec /run/current-system/sw/bin/systemctl reboot
        else
          exec /run/current-system/sw/bin/initctl reboot
        fi
      }

      verify_staged() { # system cmdline - prove the staged slot is bootable
        local system=$1 cmdline=$2 init_path magic
        # bzImage carries "HdrS" magic at offset 0x202.
        magic=$(dd if="$system/kernel" bs=1 skip=514 count=4 2>/dev/null) || true
        [ "$magic" = "HdrS" ] || die "$system/kernel is not a bzImage (HdrS magic missing)"
        # initrd starts with the early-ucode cpio ("070701") or gzip (1f8b).
        magic=$(dd if="$system/initrd" bs=1 count=2 2>/dev/null | od -An -tx1 | tr -d ' \n')
        case "$magic" in
          1f8b|3037) ;;
          *) die "$system/initrd has unexpected magic bytes: $magic" ;;
        esac
        # init= must resolve inside the rooted closure.
        init_path=$(printf '%s\n' "$cmdline" | tr ' ' '\n' | sed -n 's/^init=//p' | head -n1)
        [ -n "$init_path" ] || die "cmdline has no init= parameter"
        [ -e "$init_path" ] || die "init path missing from store: $init_path"
        echo "==> staged slot verified: bzImage+initrd magic ok, init= present"
      }

      do_install() {
        local system cmdline slot changed
        system=$1 cmdline=$2
        [ -e "$system/kernel" ] && [ -e "$system/initrd" ] || die "$system lacks kernel/initrd"
        slot=$(basename "$system" | cut -c1-8)
        mkdir -p "$island/kernels/$slot"

        copy_changed "$system/kernel" "$island/kernels/$slot/kernel"
        # Early microcode: the BIOS may ship ancient ucode and every kexec-era
        # finix boot silently inherited the ucode NixOS loaded earlier in the
        # power cycle - but direct firmware boots run the raw BIOS ucode, and
        # 2/2 of them misbehaved on the server (00:19 early hang; 10:28Z hard
        # freeze after 5.5h, mid-heartbeat, zero kernel output, watchdog
        # no-show). Prepend the early-ucode cpio exactly like NixOS does so
        # direct boots match.
        tmp_initrd=$(mktemp /tmp/finix-island-initrd.XXXXXX)
        cat ${ucodeImg} "$system/initrd" > "$tmp_initrd"
        copy_changed "$tmp_initrd" "$island/kernels/$slot/initrd"
        rm -f "$tmp_initrd"
        write_file "$island/kernels/$slot/cmdline" "$cmdline"
        write_file "$island/kernels/$slot/system" "$system"
        copy_changed ${pkgs.limine}/share/limine/BOOTX64.EFI "$island/BOOTX64.EFI"
        # Prove the staged files (not just the store inputs) are boot-shaped.
        verify_staged "$island/kernels/$slot" "$cmdline"

        # The booted slot execs init out of /nix/store: root its closure.
        "$system/sw/bin/nix-store" --realise "$system" \
          --add-root "/nix/var/nix/gcroots/finix-esp-$slot" >/dev/null

        read_state
        changed=0
        if [ "$cur" != "$slot" ]; then
          prev=$cur
          cur=$slot
          changed=1
        fi
        printf 'current=%s\nprevious=%s\n' "$cur" "$prev" > "$state.tmp" && mv "$state.tmp" "$state"

        render_conf "$cur" "$prev"
        prune_slots "$cur" "$prev"
        clean_stale
        ensure_entry
        verify_fallhome
        if [ "$changed" = 1 ]; then
          demote
          echo "==> slot $cur staged as island default; BootOrder forced NixOS-first (test window open)"
          echo "==> next: oneshot, then promote after health checks"
        else
          echo "==> slot $cur refreshed in place (BootOrder untouched)"
        fi
        sync
      }

      do_oneshot() {
        local num
        read_state
        [ -n "$cur" ] && [ -f "$island/kernels/$cur/kernel" ] || die "island not installed (run install)"
        num=$(entry_num "$label")
        [ -n "$num" ] || die "no $label EFI entry (run install)"
        demote
        efibootmgr -q -n "$num"
        echo "==> BootOrder NixOS-first (fall-home); BootNext=Boot$num -> Finix slot $cur"
        echo "==> rebooting now"
        reboot_now
      }

      do_promote() {
        local num rest current_boot
        num=$(entry_num "$label")
        [ -n "$num" ] || die "no $label EFI entry"
        current_boot=$(efibootmgr | sed -n 's/^BootCurrent: //p')
        if [ "$current_boot" != "$num" ] && [ "''${1:-}" != --force ]; then
          die "BootCurrent=$current_boot is not the Finix island (Boot$num); promote only from a healthy island boot (or pass promote-force)"
        fi
        rest=$(order_without "$num")
        efibootmgr -q -o "$num''${rest:+,$rest}"
        echo "==> BootOrder now Finix-first: $(boot_order)"
        echo "==> NixOS rescue stays one BootNext away: sudo boot-nixos (finix) / efibootmgr -n <Limine> (either OS)"
      }

      do_rollback() {
        read_state
        [ -n "$prev" ] || die "no previous slot recorded"
        [ -f "$island/kernels/$prev/cmdline" ] || die "previous slot $prev missing from ESP"
        printf 'current=%s\nprevious=%s\n' "$prev" "$cur" > "$state.tmp" && mv "$state.tmp" "$state"
        render_conf "$prev" "$cur"
        sync
        echo "==> island default now $prev (was $cur); reboot to take effect"
      }

      do_bootnext_test() {
        # Zero-risk firmware validation: one-shot into the Limine entry. Both
        # outcomes land in NixOS; success = BootCurrent equals the Limine entry
        # afterwards and BootNext is gone, proving this firmware honors BootNext.
        local lim
        lim=$(entry_num Limine)
        [ -n "$lim" ] || die "no Limine EFI entry"
        efibootmgr -q -n "$lim"
        echo "==> BootNext=Boot$lim (Limine/NixOS); rebooting - verify with status afterwards"
        reboot_now
      }

      do_status() {
        echo "== EFI =="
        efibootmgr | grep -E '^(BootCurrent|BootNext|BootOrder|Timeout)|Limine|Finix|finix' || true
        echo
        echo "== island =="
        if [ -f "$state" ]; then
          cat "$state"
          ls -1 "$island/kernels" 2>/dev/null | sed 's/^/slot: /'
          echo "-- limine.conf --"
          cat "$conf" 2>/dev/null || true
        else
          echo "not installed"
        fi
        echo
        echo "== fall-home =="
        verify_fallhome && echo "fall-home OK"
      }

      action=''${1:-status}
      shift || true
      case "$action" in
        install)
          if [ "''${3:-}" = --require-fallhome ]; then require_fallhome=1; fi
          do_install "''${1:?system path required}" "''${2:?cmdline required}"
          ;;
        oneshot) do_oneshot ;;
        promote) do_promote "''${1:-}" ;;
        demote) demote; echo "==> BootOrder NixOS-first: $(boot_order)" ;;
        rollback) do_rollback ;;
        bootnext-test) do_bootnext_test ;;
        status) do_status ;;
        *) die "unknown action: $action" ;;
      esac
    '';

    # Operator-side driver. host = "local": the island script runs directly
    # on this machine under sudo (the desktop drives its own ESP; nix copy
    # and ssh do not apply). Any other host: ssh via the LAN IP - Tailscale
    # SSH in check mode intercepts tailnet-resolved names and waits forever
    # on a browser auth, so automation targets the classic sshd path.
    bootDriverScript = pkgs.writeShellScriptBin name ''
      set -euo pipefail

      host="''${1:-${defaultHost}}"
      action="''${2:-status}"
      case "$host" in
        *[!A-Za-z0-9_.:@-]*)
          echo "invalid host: $host" >&2
          exit 2
          ;;
      esac
      case "$action" in
        status|bootnext-test|install|install-require-fallhome|oneshot|promote|promote-force|demote|rollback) ;;
        *)
          echo "usage: ${name} [host|local] [status|bootnext-test|install|install-require-fallhome|oneshot|promote|promote-force|demote|rollback]" >&2
          exit 2
          ;;
      esac

      system_path='${system}'
      island='${espIslandScript}'

      cmdline_from_bootspec() {
        bootjson="$system_path/boot.json"
        init="$(${pkgs.jq}/bin/jq -r '.["org.nixos.bootspec.v1"].init' "$bootjson")"
        kernel_params="$(${pkgs.jq}/bin/jq -r '.["org.nixos.bootspec.v1"].kernelParams | join(" ")' "$bootjson")"
        printf 'init=%s %s' "$init" "$kernel_params"
      }

      if [ "$host" = local ]; then
        case "$action" in
          install)
            exec sudo "$island" install "$system_path" "$(cmdline_from_bootspec)"
            ;;
          install-require-fallhome)
            exec sudo "$island" install "$system_path" "$(cmdline_from_bootspec)" --require-fallhome
            ;;
          promote-force)
            exec sudo "$island" promote --force
            ;;
          *)
            exec sudo "$island" "$action"
            ;;
        esac
      fi

      # post-NixOS-purge: running finix supplies nix-store (same as deploy.nix)
      remote_store="ssh://$host?remote-program=/run/current-system/sw/bin/nix-store"
      sshopts="-o BatchMode=yes -o ConnectTimeout=10 -o ControlMaster=no -o ControlPath=none"
      export NIX_SSHOPTS="$sshopts"

      remote_args=""
      case "$action" in
        install|install-require-fallhome)
          cmdline="$(cmdline_from_bootspec)"
          echo "==> copying island tooling + persistent closure to $host"
          nix copy --to "$remote_store" "$island" "$system_path"
          remote_args=" '$system_path' '$cmdline'"
          if [ "$action" = install-require-fallhome ]; then remote_args="$remote_args '--require-fallhome'"; fi
          action=install
          ;;
        promote-force)
          action=promote
          remote_args=" '--force'"
          nix copy --to "$remote_store" "$island"
          ;;
        *)
          nix copy --to "$remote_store" "$island"
          ;;
      esac

      remote_cmd="/run/wrappers/bin/sudo '$island' '$action'$remote_args"
      case "$action" in
        oneshot|bootnext-test)
          # The remote end reboots; the dropped connection is expected.
          ssh $sshopts "$host" "$remote_cmd" || true
          ;;
        *)
          ssh $sshopts "$host" "$remote_cmd"
          ;;
      esac

      case "$action" in
        bootnext-test)
          cat <<MSG

      box rebooting via BootNext into the Limine entry (NixOS either way).
      verify afterwards:  ${name} $host status
        expect: BootCurrent = the Limine entry, no BootNext line.
      MSG
          ;;
        oneshot)
          cat <<MSG

      one-shot island boot initiated:
        - success: ssh to $host comes back as finix (direct boot, no kexec)
        - kernel/initrd trouble: panic=30 + BootOrder fall back to NixOS
        - pre-OS hang (no panic): power-cycle -> NixOS (BootOrder is safe)
      then:  ${name} $host promote
      MSG
          ;;
      esac
    '';
  };
}
