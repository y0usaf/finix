_: {
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/log"
      "/etc/ssh"
      "/var/lib/docker"
      "/var/lib/tailscale"
      "/var/lib/hjem"
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"
    ];
    files = [
      "/etc/machine-id"
    ];
  };
}
