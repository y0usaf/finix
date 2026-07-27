# Shared impermanence allowlist: entries every host persists. Host modules
# merge their extras on top with `++`.
#
# Pure data — NO function args, lib, pkgs, or config. finix
# (modules/finix/hosts/*/persistent.nix) imports the host impermanence.nix, calls it
# with {}, and replays the resulting lists as plain bind mounts; everything
# reachable from there must stay literal (import/++ only). This file lives
# outside hosts/<host>/ so recursivelyImport never picks it up as a module.
{
  systemDirectories = [
    # System identity & NixOS state
    "/var/lib/nixos"
    "/var/lib/systemd/coredump"
    "/var/log"

    # SSH host keys
    "/etc/ssh"

    # Network
    "/etc/NetworkManager/system-connections"
    "/var/lib/NetworkManager"
    "/var/lib/tailscale"

    # Services
    "/var/lib/manzil"
  ];

  systemFiles = [
    "/etc/machine-id"
  ];

  userDirectories = [
    # Data (dev excluded — real @dev subvol, fileSystems entry)
    "Documents"
    "Tokens"
    "nixos"

    # Identity / credentials
    ".ssh"

    # Browsers
    ".mozilla"
    ".librewolf"

    # AI / dev tooling state — relocated out of ~ via env vars in
    # modules/core/user/session/xdg.nix (CLAUDE_CONFIG_DIR, CODEX_HOME,
    # PI_CODING_AGENT_DIR, KIMI_CODE_HOME). ~/.claude.json lives inside
    # the claude dir once CLAUDE_CONFIG_DIR is set.
    ".local/share/claude"
    ".local/share/codex"
    ".local/share/pi"
    ".local/share/kimi-code" # config.toml (API key), sessions, logs

    # ~/.config
    ".config/gh" # hosts.yml oauth
    ".config/gws" # google oauth creds (client_secret, .encryption_key)
    ".config/librewolf"

    # ~/.local/state
    ".local/state/nix"

    # Caches worth keeping
    ".cache/nix"
  ];

  userFiles = [
  ];
}
