{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services.tailscale.enableVPN {
    services.tailscale = {
      enable = true;
      # Allow incoming connections on the Tailscale interface
      openFirewall = true;
    };

    # Restart Tailscale after suspend/resume to fix connectivity
    systemd.services.tailscale-resume = {
      description = "Restart Tailscale after resume";
      wantedBy = ["suspend.target"];
      after = ["suspend.target"];
      script = "${config.systemd.package}/bin/systemctl restart tailscaled.service";
      serviceConfig.Type = "oneshot";
    };

    # Optional: Enable Tailscale exit node capability
    # Uncomment to allow this device to route traffic for other Tailscale devices
    # boot.kernel.sysctl."net.ipv4.ip_forward" = true;
    # boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = true;
  };
}
