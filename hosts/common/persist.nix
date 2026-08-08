# Shared impermanence allowlist: entries every host persists. Host modules
# merge their extras on top with `++`.
#
# Pure data — NO function args, lib, pkgs, or config. finix
# (finix/hosts/*/persistent.nix) imports the host impermanence.nix, calls it
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
    "finix"

    # Identity / credentials
    ".ssh"
    ".azure" # azure-cli msal token cache (~/.azure/msal_token_cache.json)

    # AI / dev tooling state — relocated out of ~ via env vars in
    # modules/core/user/session/xdg.nix (CLAUDE_CONFIG_DIR, CODEX_HOME,
    # KIMI_CODE_HOME). ~/.claude.json lives inside the claude dir once
    # CLAUDE_CONFIG_DIR is set. pi uses its own default ~/.pi/agent.
    # claude: subdirs only — versions/ (218M binary cache) regenerates on next app
    # start; settings.json is a manzil symlink (regenerates).
    ".local/share/claude/backups"
    ".local/share/claude/cache"
    ".local/share/claude/plugins"
    ".local/share/claude/projects"
    ".local/share/claude/sessions"
    ".local/share/claude/tasks"
    ".local/share/claude/teams"
    ".local/share/claude/.claude"
    ".local/share/codex"
    ".pi" # pi agent dir (pi's native default; no env var indirection)
    ".prime" # prime agent dir (agents, sessions, daemon state, logs)

    # ~/.config
    ".config/gh" # hosts.yml oauth
    ".config/gws" # google oauth creds (client_secret, .encryption_key)

    # ~/.local/state
    ".local/state/nix"

    # Caches worth keeping
    ".cache/nix"
  ];

  userFiles = [
    ".local/share/claude/.claude.json"
    ".local/share/claude/history.jsonl"
  ];
}
