{pkgs, ...}: {
  config = {
    services.dbus = {
      enable = true;
      packages = [
        pkgs.dconf
        pkgs.gcr
      ];
    };
  };
}
