{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services.tailscale.enableVPN {
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };

    systemd.services.tailscale-resume = {
      description = "Restart Tailscale after resume";
      wantedBy = ["suspend.target"];
      after = ["suspend.target"];
      script = "${config.systemd.package}/bin/systemctl restart tailscaled.service";
      serviceConfig.Type = "oneshot";
    };
  };
}
