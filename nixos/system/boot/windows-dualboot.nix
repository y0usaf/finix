{
  lib,
  config,
  ...
}: let
  cfg = config.boot.windowsDualBoot;
in {
  options.boot.windowsDualBoot = {
    enable = lib.mkEnableOption "Windows dual-boot via Limine chainload";
    windowsEfiPartuuid = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "09d3f11d-33f2-442b-9971-c279ef51860f";
      description = "PARTUUID of the Windows EFI System Partition.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader.limine.extraEntries = ''
      /+Windows Boot Manager
        protocol: chainload
        path: ${
        if cfg.windowsEfiPartuuid != null
        then "uuid(${cfg.windowsEfiPartuuid})"
        else "boot()"
      }:/EFI/Microsoft/Boot/bootmgfw.efi
    '';
  };
}
