# Shared persistence data for hosts that still use the compact allowlist.
# Keep pure: Finix imports this as data and replays it as bind mounts.
{
  systemDirectories = [
    "/var/lib/nixos"
    "/var/lib/systemd/coredump"
    "/var/log"
    "/etc/ssh"
    "/etc/NetworkManager/system-connections"
    "/var/lib/NetworkManager"
    "/var/lib/tailscale"
    "/var/lib/manzil"
  ];

  systemFiles = [
    "/etc/machine-id"
  ];

  userDirectories = [
    "Dev"
    "Documents"
    "Tokens"
    "nixos"
    ".ssh"
    ".fx"
    ".mozilla"
    ".librewolf"
    ".local/share/claude"
    ".local/share/codex"
    ".local/share/pi"
    ".local/share/kimi-code"
    ".config/gh"
    ".config/gws"
    ".config/librewolf"
    ".local/state/nix"
    ".cache/nix"
  ];

  userFiles = [];
}
