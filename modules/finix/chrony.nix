{pkgs, ...}: {
  services.chrony = {
    enable = true;
    configFile = pkgs.writeText "chrony.conf" ''
      pool pool.ntp.org iburst
      makestep 1.0 3
      rtcsync
      driftfile /var/lib/chrony/drift
    '';
  };
}
