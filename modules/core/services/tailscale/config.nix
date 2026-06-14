{
  config,
  lib,
  ...
}: {
  options.services.tailscale.enableVPN = lib.mkEnableOption "Enable Tailscale VPN mesh network";

  config = lib.mkIf config.services.tailscale.enableVPN {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      extraUpFlags = ["--ssh"];
    };

    # Tailnet peers are already authenticated; trust the interface so services
    # are reachable over the tailnet without opening their ports on LAN.
    networking.firewall.trustedInterfaces = ["tailscale0"];

    systemd.services.tailscale-resume = {
      description = "Restart Tailscale after resume";
      wantedBy = ["suspend.target"];
      after = ["suspend.target"];
      script = "${config.systemd.package}/bin/systemctl restart tailscaled.service";
      serviceConfig.Type = "oneshot";
    };
  };
}
