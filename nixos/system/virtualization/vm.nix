{
  lib,
  config,
  ...
}: {
  options = {
    virtualisation = {
      qemu = {
        enable = lib.mkEnableOption "QEMU/KVM virtualization";
      };
    };
  };

  config = lib.mkIf config.virtualisation.qemu.enable {
    virtualisation = {
      libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true;
          ovmf.enable = true;
          runAsRoot = false;
        };
      };
    };

    programs = {
      virt-manager = {
        enable = true;
      };
    };
  };
}
