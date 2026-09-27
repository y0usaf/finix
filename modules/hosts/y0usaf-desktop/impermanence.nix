_: {
  finix.persistence.allowlist = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/etc/ssh"
      {
        directory = "/root";
        mode = "0700";
      }
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"
      "/var/lib/btrbk"
      "/var/lib/manzil"
      "/var/lib/nixos"
      "/var/lib/sbctl"
      "/var/lib/systemd/coredump"
      "/var/lib/tailscale"
      "/var/log"
    ];
    files = ["/etc/machine-id"];
    users.y0usaf = {
      directories = [
        ".azure"
        ".cache/nix"
        ".cache/nv"
        ".config/AionUi"
        ".config/Frame"
        ".config/GitHub Desktop"
        ".config/Hermes"
        ".config/age"
        ".config/agent-harness"
        ".config/camset"
        ".config/claude"
        ".config/dconf"
        ".config/epy"
        ".config/firefox"
        ".config/herdr"
        ".config/intent"
        ".config/manicode"
        ".config/nix"
        ".config/slskd"
        ".config/snowflake"
        ".cookunity"
        ".cursor/sand"
        ".cursor/sand-dev"
        ".hermes"
        ".local/share/Vial"
        ".local/share/app.codeg"
        ".local/share/com.jean.desktop"
        ".local/share/com.panes.app"
        ".local/share/gnupg"
        ".local/share/keyrings"
        ".local/share/mcp-trader"
        ".local/share/music-get"
        ".local/share/pki"
        ".local/share/polybot"
        ".local/share/slskd"
        ".local/share/superfile"
        ".local/share/vibe-kanban"
        ".local/state/bash"
        ".local/state/music-get"
        ".local/state/nix"
        ".local/state/superfile"
        ".mcp-auth"
        ".n8n-mcp"
        ".paseo"
        ".pki"
        ".slskd"
        ".supabase"
        "Desktop"
        "Documents"
        "Downloads"
        "Games"
        "Tokens"
        "Videos"
        "cu-workbench"
        "finix"
        "inscend"
      ];
      files = [
        ".SNOW"
      ];
    };
  };
}
