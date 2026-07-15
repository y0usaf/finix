_: {
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      # System identity & NixOS state
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/log"

      # Root user state (agents, ssh)
      {
        directory = "/root";
        mode = "0700";
      }

      # SSH host keys & secure boot signing keys
      "/etc/ssh"
      "/var/lib/sbctl"

      # Network
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"
      "/var/lib/tailscale"

      # Services
      "/var/lib/docker"
      "/var/lib/manzil"
      "/var/lib/btrbk"
      "/var/lib/fwupd"
      "/var/lib/hjem"
      "/var/lib/bayt"
    ];
    files = [
      "/etc/machine-id"
    ];
    users.y0usaf = {
      directories = [
        # NOTE: .config, .local, DCIM, Music, Pictures, Steam are dedicated
        # btrfs subvols mounted on top of /home — NOT listed here.

        # Data
        "Dev"
        "Documents"
        "Downloads"
        "Desktop"
        "Videos"
        "Games"
        "Tokens"
        "nixos"
        "cookunity"
        "inscend"
        "shoji_wm"

        # Identity / credentials
        ".ssh"
        ".pki"
        ".aws"
        ".mcp-auth"
        ".git"

        # Browsers
        ".mozilla"
        ".librewolf"

        # AI / dev tooling state
        ".claude"
        ".claude-code-router"
        ".codex"
        ".gemini"
        ".crush"
        ".pi"
        ".cookunity"
        ".forge"
        ".jcode"
        ".nexau"
        ".phi"
        ".omp"
        ".slack"
        ".supabase"
        ".n8n-mcp"
        ".obsidian"

        # Toolchains
        ".cargo"
        ".rustup"
        ".bun"
        ".npm"
        ".java"
        ".android"
        ".vcpkg"
        ".nimble"
        ".biome"
        ".jdeploy"
        ".triton"

        # Gaming / apps
        ".steam"
        ".SteamCloud"
        ".minecraft"
        ".stremio-server"
        ".slskd"
        ".SNOW"

        # Caches worth keeping (shader/compile caches; .cache itself not a subvol)
        ".cache/nix"
        ".cache/nvidia"
        ".cache/mesa_shader_cache"
        ".cache/mesa_shader_cache_db"
        ".cache/wallust"
        ".cache/ekko"
        ".cache/librewolf"
        ".cache/mozilla"
        ".nv"
      ];
      files = [
        ".claude.json"
      ];
    };
  };
}
