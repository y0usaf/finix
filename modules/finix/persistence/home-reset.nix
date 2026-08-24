{
  config,
  lib,
  ...
}: let
  cfg = config.finix.persistence.homeReset;
in {
  options.finix.persistence.homeReset = {
    enable = lib.mkEnableOption "Btrfs home reset from a blank snapshot";
    btrfsRoot = lib.mkOption {
      type = lib.types.str;
      default = "/sysroot/btrfs";
      description = "Initrd mount containing the top-level Btrfs subvolumes.";
    };
    homeSubvolume = lib.mkOption {
      type = lib.types.str;
      default = "@home";
      description = "Live home subvolume name.";
    };
    templateSubvolume = lib.mkOption {
      type = lib.types.str;
      default = "@home-blank";
      description = "Blank home snapshot template.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.finit.tasks = {
      reset-home = {
        description = "rotate home back to the blank Btrfs template";
        conditions = ["task/mount-btrfs/success"];
        script = ''
          B=${cfg.btrfsRoot}
          live="$B/${cfg.homeSubvolume}"
          fresh="$B/${cfg.homeSubvolume}-new"
          previous="$B/${cfg.homeSubvolume}-lastboot"
          template="$B/${cfg.templateSubvolume}"

          if ! btrfs subvolume show "$live" >/dev/null 2>&1; then
            if btrfs subvolume show "$fresh" >/dev/null 2>&1; then
              mv "$fresh" "$live" || { echo "reset-home: FATAL: promote fresh home failed" >&2; exit 1; }
            elif btrfs subvolume show "$previous" >/dev/null 2>&1; then
              mv "$previous" "$live" || { echo "reset-home: FATAL: restore previous home failed" >&2; exit 1; }
            else
              echo "reset-home: FATAL: no recoverable home subvolume" >&2
              exit 1
            fi
            exit 0
          fi

          if btrfs subvolume show "$fresh" >/dev/null 2>&1; then
            btrfs subvolume delete "$fresh" || { echo "reset-home: skip: stale fresh snapshot could not be deleted"; exit 0; }
          fi
          if ! btrfs subvolume show "$template" >/dev/null 2>&1; then
            echo "reset-home: skip: no template"
            exit 0
          fi
          btrfs subvolume snapshot "$template" "$fresh" || { echo "reset-home: skip: snapshot failed"; exit 0; }
          if btrfs subvolume show "$previous" >/dev/null 2>&1; then
            btrfs subvolume delete "$previous" || {
              btrfs subvolume delete "$fresh" || true
              echo "reset-home: skip: previous snapshot could not be deleted"
              exit 0
            }
          fi
          mv "$live" "$previous" || {
            btrfs subvolume delete "$fresh" || true
            echo "reset-home: skip: live rotation failed"
            exit 0
          }
          mv "$fresh" "$live" || {
            mv "$previous" "$live" || true
            echo "reset-home: skip: promotion failed; rolled back"
            exit 0
          }
          echo "reset-home: success"
        '';
      };
      "mount-home".conditions = ["task/reset-home/success"];
    };
  };
}
