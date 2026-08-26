# Single persistence allowlist for y0usaf-desktop — one place to edit.
#
# Also the finix system's persist allowlist: hosts/y0usaf-desktop/finix/*
# calls this function and replays these lists as plain bind mounts. Keep it
# pure literals (import/++ only, no lib/pkgs/config) so both module universes
# can read it.
#
# Browser paths (firefox/librewolf/discord/vesktop) are persisted
# unconditionally: a disabled app just leaves an empty dir on /persist.
_: let
  gameSaves = [
    "dolphin-emu"
    "Cemu"
    "shipofharkinian"
    "bolt-launcher"
    "osu"
    "wine"
    "skua-wine"
    "balatroai"
    "Celeste"
    "CassetteBeasts"
    "Brotato"
    "Baba_Is_You"
    "binding of isaac rebirth"
    "HallsOfTorment"
    "YourOnlyMoveIsHUSTLE"
    "Rocket League"
    "SteamWorld Heist"
    "shapez.io"
    "lootplot"
    "hackerpg"
    "com.overboy.noobsarecoming"
    "Noobs Are Coming (Save)"
    ".renpy"
    ".Wurst encryption"
    "aspyr-media"
    "Smart Code ltd"
  ];
in {
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
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

      # Root user state (agents, ssh)
      {
        directory = "/root";
        mode = "0700";
      }

      # Secure boot signing keys
      "/var/lib/sbctl"

      # Bluetooth pairing
      "/var/lib/bluetooth"

      # Docker engine state
      "/var/lib/docker"

      # Waydroid Android container (TFT) — image, userdata, installed apps
      "/var/lib/waydroid"

      # Backup / automation
      "/var/lib/btrbk"
      "/var/lib/hjem"
      "/var/lib/bayt"
    ];
    files = [
      "/etc/machine-id"
    ];
    users.y0usaf = {
      directories =
        [
          # Data (dev excluded — real @dev subvol, fileSystems entry)
          "Documents"
          "Tokens"
          "finix"
          "Downloads"
          "Desktop"
          "Videos"
          "Games"
          "cu-workbench"
          "inscend"

          # Identity / credentials
          ".ssh"
          ".azure" # azure-cli msal token cache (~/.azure/msal_token_cache.json)
          ".pki"
          ".aws"
          ".mcp-auth"

          # AI / dev tooling state
          ".fx" # fx settings, sessions, skills, and durable agent state
          ".omfx" # oh my fx profile settings (startup_mode and fork-only keys)
          ".pi" # pi agent dir (pi's native default; no env var indirection)
          ".omp" # oh-my-pi agent dir (sessions, harness config.json)
          ".prime" # prime agent dir (agents, sessions, daemon state, logs)
          ".hermes" # desktop app HERMES_HOME (config, sessions, skills dirs)
          ".crush"
          ".cookunity"
          ".phi"
          ".paseo" # paseo daemon state (config.json, phone pairing, sessions)
          ".slack"
          ".supabase"
          ".n8n-mcp"
          ".obsidian"

          # Browsers — persisted unconditionally (empty dir when disabled)
          # Firefox 147+: XDG dirs (~/.config/firefox) unless ~/.mozilla/firefox
          # exists or MOZ_LEGACY_HOME=1. Empty ~/.mozilla alone is not legacy.
          ".config/firefox"
          # LibreWolf 152 reads the legacy ~/.librewolf only (no XDG support).
          ".librewolf"
          ".config/discord"
          ".config/vesktop"
          ".config/Vencord"

          # Gaming / apps
          ".steam"
          ".SteamCloud"
          ".stremio-server"
          ".slskd"

          ### ~/.config — mutable app state only. Nix/manzil-generated configs
          ### (bash rc, niri, foot, wallust, gtk, mpv, git, gh config,
          ### npm/bun/docker/python rc, pi, mangohud, ...) regenerate on switch.

          # Credentials / identity
          ".config/gh" # hosts.yml oauth
          ".config/gws" # google oauth creds (client_secret, .encryption_key)
          ".config/age"
          ".config/aws"
          ".config/gcloud"

          # Slack is persisted selectively — auth/session storage only, caches
          # (Cache, Code Cache, GPUCache, Service Worker, Crashpad, logs, sentry)
          # stay ephemeral.
          ".config/Slack/Local Storage"
          ".config/Slack/Session Storage"
          ".config/Slack/IndexedDB"
          ".config/Slack/storage"

          # Sync (device keys + index — critical)
          ".config/syncthing"

          # AI / editors / IDEs
          ".config/AionUi"
          ".config/Claude"
          ".config/Hermes" # Electron userData — remote-gateway session (hermes desktop)
          ".config/Codex"
          ".config/opencode"
          ".config/manicode"
          ".config/agent-harness"
          ".config/pi-harness"
          ".config/crush"
          ".config/phi"

          # Desktop apps
          ".config/obsidian"
          ".config/obs-studio"
          ".config/qBittorrent"
          ".config/stoat-desktop"
          ".config/slskd"
          ".config/epy"
          ".config/cmus" # library/playlists
          ".config/GitHub Desktop"

          # Work
          ".config/gws-inscend"
          ".config/Frame"
          ".config/intent"
          ".config/herdr"
          ".config/ramp" # ramp-cli config.toml + auth state

          # Misc
          ".config/snowflake"
          ".config/camset"

          # Gaming
          ".config/Cemu"
          ".config/unity3d" # game prefs
          ".config/bolt-launcher"

          # Misc state
          ".config/dconf"
          ".config/nix" # possible access-tokens
          ".config/ekko" # config.toml + extensions (app-owned)

          # ekko cache: resurrection manifests MUST survive reboots for `ekko attach`;
          # daemon logs ride along. Persist the whole dir (small).
          ".cache/ekko"

          ### ~/.local/share — real data/saves. Caches (go, gradle, pnpm, uv,
          ### NuGet, yarn, pyenv, virtualenv, Trash, ...) are ephemeral.

          # Keys / identity
          ".local/share/gnupg"
          ".local/share/keyrings"
          ".local/share/pki"

          # Big data (flagged: prune candidates, but keep)
          ".local/share/PrismLauncher" # 55G — minecraft worlds, irreplaceable
          ".local/share/bun" # globals only (supabase/...); install/cache purged, regenerates
          ".local/share/cargo"
          ".local/share/rustup"
          ".local/share/opencode"
          ".local/share/phi"
          ".local/share/nvim"
        ]
        ++ builtins.map (n: ".local/share/${n}") gameSaves
        ++ [
          # Emulation / gaming saves appended above via gameSaves

          # Apps
          ".local/share/stremio"
          ".local/share/stremio-linux-shell" # stremio v1.1.4+ WebKitGTK profile (login session/site data)
          ".local/share/slskd"
          ".local/share/Vial"

          # adb keypair kept; sdk cache + debug.keystore stay ephemeral
          ".local/share/android/.android"
          ".local/share/waydroid" # Android /data — Play/GMS login, TFT, installed apps (session binds it in)
          ".local/share/mcp-trader"
          ".local/share/music-get"
          ".local/share/polybot"
          ".local/share/rtk"
          ".local/share/vibe-kanban"
          ".local/share/superfile"
          ".local/share/crush"
          ".local/share/ai.opencode.desktop"
          ".local/share/app.codeg"
          ".local/share/com.jean.desktop"
          ".local/share/com.panes.app"
          ".local/share/com.vercel.cli"
          ".local/share/com.vercel.token"
          ".local/share/syncthing"

          ### ~/.local/state — histories & app state
          ".local/state/nix"
          ".local/state/bash" # shell history
          ".local/state/rush" # rush history.sqlite (modules/core/user/session/xdg.nix)
          ".local/state/nvim" # shada/undo
          ".local/state/pi-harness"
          ".local/state/syncthing" # index
          ".local/state/wireplumber" # audio device volumes
          ".local/state/music-get"
          ".local/state/superfile"

          # Caches worth keeping
          ".cache/nix"
        ];
      files = [
        # adb keypair kept; sdk cache + debug.keystore stay ephemeral
        ".local/share/android/adbkey"
        ".local/share/android/adbkey.pub"

        ".config/Slack/Local State"
        ".config/Slack/Preferences"
        ".config/Slack/Cookies"
        ".config/Slack/Cookies-journal"
        ".config/Slack/Network Persistent State"
        ".config/Slack/TransportSecurity"

        ".SNOW"
      ];
    };
  };
}
