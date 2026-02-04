{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.boot.windowsDualBoot;
in {
  options.boot.windowsDualBoot = {
    enable = lib.mkEnableOption "Windows dual-boot helpers (Limine chainload + BootOrder fix)";
    forceBootOrder = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Force Limine to stay first in UEFI BootOrder at boot.";
    };
    windowsEfiPartuuid = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "09d3f11d-33f2-442b-9971-c279ef51860f";
      description = "PARTUUID of the Windows EFI System Partition. When set, Limine will chainload via uuid(PARTUUID) instead of boot().";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader.limine.extraEntries = let
      locator =
        if cfg.windowsEfiPartuuid != null
        then "uuid(${cfg.windowsEfiPartuuid})"
        else "boot()";
    in ''
      /+Windows Boot Manager
        protocol: chainload
        path: ${locator}:/EFI/Microsoft/Boot/bootmgfw.efi
    '';

    environment.systemPackages = [
      pkgs.efibootmgr
      pkgs.gawk
    ];

    systemd.services.fix-uefi-boot-order = lib.mkIf cfg.forceBootOrder {
      description = "Ensure Limine stays first in UEFI BootOrder";
      wantedBy = ["multi-user.target"];
      after = ["local-fs.target"];
      unitConfig = {
        ConditionPathExists = "/sys/firmware/efi/efivars";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "fix-uefi-boot-order" ''
          set -euo pipefail
          limine=$(${pkgs.efibootmgr}/bin/efibootmgr -v | ${pkgs.gawk}/bin/awk '/Boot[0-9A-F]{4}\\* Limine/ {print substr($1,5,4); exit}')
          windows=$(${pkgs.efibootmgr}/bin/efibootmgr -v | ${pkgs.gawk}/bin/awk '/Boot[0-9A-F]{4}\\* Windows Boot Manager/ {print substr($1,5,4); exit}')
          if [ -z "''${limine:-}" ] || [ -z "''${windows:-}" ]; then
            exit 0
          fi
          ${pkgs.efibootmgr}/bin/efibootmgr -o "''${limine},''${windows}"
        '';
      };
    };
  };
}
