_: {
  finix.persistence.allowlist = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/etc/ssh"
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"
      "/var/lib/manzil"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/tailscale"
      "/var/log"
    ];
    files = ["/etc/machine-id"];
    users.y0usaf = {
      directories = [
        ".cache/mesa_shader_cache"
        ".cache/nv"
        ".config/Mullvad VPN"
        ".config/claude"
        ".config/dconf"
        ".config/nix"
        ".config/nushell"
        ".local/share/applications"
        ".local/share/azure"
        ".local/share/com.pais.handy"
        ".local/share/handy"
        ".local/share/icons"
        ".local/share/pki"
        ".local/state/bash"
        ".local/state/manzil"
        ".local/state/nix"
        ".mozilla"
        "Documents"
        "Tokens"
        "cu-workbench"
        "finix"
      ];
      files = [".npmrc"];
    };
  };
}
