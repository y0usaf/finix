_: {
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/log"
      "/etc/ssh"
      "/etc/NetworkManager/system-connections"
      "/var/lib/docker"
      "/var/lib/tailscale"
      "/var/lib/hjem"
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"
    ];
    files = [
      "/etc/machine-id"
    ];
    users.y0usaf = {
      directories = [
        ".cache/librewolf"
        ".cache/zellij"
        ".cache/wallust"
        ".config"
        ".claude"
        ".librewolf"
        ".codex"
        ".local"
        ".mozilla"
        ".ssh"
        ".steam"
        "DCIM"
        "Dev"
        "Documents"
        "Music"
        "Pictures"
        "Tokens"
        "nixos"
      ];
      files = [
        ".claude.json"
      ];
    };
  };
}
