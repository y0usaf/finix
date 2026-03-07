_: {
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      # System identity & NixOS state
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/log"

      # SSH host keys
      "/etc/ssh"

      # Services
      "/var/lib/postgresql"
      "/var/lib/forgejo"
      "/var/lib/private" # n8n, blocky (systemd DynamicUser dirs)
      "/var/lib/docker"
      "/var/lib/tailscale"
      "/var/lib/hjem"
      "/var/lib/btrbk"
      "/var/lib/NetworkManager"
    ];
    files = [
      "/etc/machine-id"
    ];
  };
}
