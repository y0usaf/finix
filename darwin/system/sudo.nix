{pkgs, ...}: {
  # Allow passwordless sudo for nh
  security.sudo.extraConfig = ''
    %admin ALL=(ALL:ALL) NOPASSWD: ${pkgs.nh}/bin/nh
  '';
}
