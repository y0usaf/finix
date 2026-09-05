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
    ".omfx" # oh my fx settings
    ".mozilla"
    ".librewolf"
    ".local/share/pi"
    ".config/gh"
    ".config/gws"
    ".config/librewolf"
    ".local/state/nix"
    ".config/pi/agent"       # RETIRED 2026-09-02: PI_CODING_AGENT_DIR reverted (pi/omp both read it; shared-dir hazard); pi back on native ~/.pi (allowlisted separately). Contents migrated back to ~/.pi; safe to drop.
    ".config/codex"          # CODEX_HOME cutover
    ".local/share/android"   # ANDROID_USER_HOME data side
    ".config/claude"          # CLAUDE_CONFIG_DIR cutover
    ".local/share/azure"      # AZURE_CONFIG_DIR cutover
    ".local/state/bash"       # HISTFILE cutover
  ];

  userFiles = [];
}
