{...}: {
  config = {
    services.udisks2 = {
      enable = true;
    };
    systemd.services.udisks2.wantedBy = ["multi-user.target"];
  };
}
