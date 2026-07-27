# Phase 1 of the finix server migration: a minimal QEMU VM that must boot,
# bring up networking, and accept SSH. Service parity (docker, forgejo,
# syncthing, ...) is layered on in later phases once this base is trusted.
_: {
  networking.hostName = "finix-server-vm";

  # Root is tmpfs; the host nix store is 9p-mounted by the qemu module.
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = ["mode=755" "size=2G"];
  };

  boot.kernelParams = ["console=ttyS0,115200n8"];

  virtualisation = {
    cores = 4;
    memorySize = 4096;
    qemu.extraArgs = ["-nographic"];
    qemu.nics.usernet.args = [
      "user"
      "model=virtio-net-pci"
      "hostfwd=tcp::22222-:22"
    ];
  };

  services.getty = {
    enable = true;
    ttys = ["ttyS0"];
  };
}
