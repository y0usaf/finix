# Shared finit desktop stack. Hardware, storage, networking, firewall, and boot
# stay host-owned; session/audio/parity/user daemons live here once for every
# graphical Finix host.
{
  imports = [
    ./audio.nix
    ./materialized-packages.nix
    ./parity.nix
    ./session.nix
    ./udev.nix
    ./user-daemons.nix
  ];
}
