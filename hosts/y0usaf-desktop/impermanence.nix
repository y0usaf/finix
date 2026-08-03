# ALSO the finix system's persist allowlist: hosts/y0usaf-desktop/finix/*
# calls this function and replays these lists as plain bind mounts. Keep it
# pure literals (import/++ only, no lib/pkgs/config) so both module universes
# can read it. Entries shared with other hosts live in ../common/persist.nix.
{config, ...}: let
  common = import ../common/persist.nix;
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
    directories =
      common.systemDirectories
      ++ [
        # Root user state (agents, ssh)
        {
          directory = "/root";
          mode = "0700";
        }

        # Secure boot signing keys
        "/var/lib/sbctl"

        # Network
        "/var/lib/bluetooth"

        # Services
        "/var/lib/docker"
        "/var/lib/btrbk"
        "/var/lib/hjem"
        "/var/lib/bayt"
      ];
    files = common.systemFiles;
    users.y0usaf = {
      directories =
        common.userDirectories
        ++ (
          if config.user.programs.firefox.enable
          # Firefox 147+: XDG dirs (~/.config/firefox) unless ~/.mozilla/firefox
          # exists or MOZ_LEGACY_HOME=1. Empty ~/.mozilla alone is not legacy.
          then [".config/firefox"]
          else []
        )
        ++ (
          if config.user.programs.librewolf.enable
          # LibreWolf 152 reads the legacy ~/.librewolf only (no XDG support),
          # so persist that. ~/.cache/librewolf stays ephemeral.
          then [".librewolf"]
          else []
        )
        ++ (
          if config.user.programs.discord.stable.enable
          then [".config/discord"]
          else []
        )
        ++ (
          if config.user.programs.discord.vesktop.enable
          then [".config/vesktop" ".config/Vencord"]
          else []
        )
        ++ ([
            # NOTE: DCIM, Music, Pictures, .local/share/Steam are dedicated
            # btrfs subvols mounted on top of /home — NOT listed here.
            # @config/@local were dissolved into the granular allowlists below;
            # anything not listed is ephemeral (recoverable from
            # /btrfs/_premigration/* snapshots until those are deleted).

            # Data
            "Downloads"
            "Desktop"
            "Videos"
            "Games"
            "cu-workbench"
            "inscend"

            # Identity / credentials
            ".pki"
            ".aws"
            ".mcp-auth"

            # AI / dev tooling state
            ".claude-code-router"
            ".hermes" # desktop app HERMES_HOME (config, sessions, skills dirs)
            ".gemini"
            ".crush"
            ".cookunity"
            ".forge"
            ".nexau"
            ".phi"

            ".slack"
            ".supabase"
            ".n8n-mcp"
            ".obsidian"

            # Gaming / apps
            ".steam"
            ".SteamCloud"

            ".stremio-server"
            ".slskd"

            ### ~/.config — mutable app state only. Nix/manzil-generated configs
            ### (bash rc, niri, foot, wallust, gtk, mpv, git, gh config,
            ### npm/bun/docker/python rc, pi, mangohud, ...) regenerate on switch.

            # Credentials / identity
            ".config/age"
            ".config/aws"
            ".config/gcloud"
            ".config/ngrok"

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
            ".local/share/bun" # globals only (supabase/vercel/...); install/cache purged, regenerates

            ".local/share/cargo"
            ".local/share/rustup"
            ".local/share/opencode"

            ".local/share/phi"

            # Emulation / gaming (saves!)
          ]
          ++ builtins.map (n: ".local/share/${n}") gameSaves
          ++ [
            # Apps

            ".local/share/stremio"
            ".local/share/stremio-linux-shell" # stremio v1.1.4+ WebKitGTK profile (login session/site data)
            ".local/share/slskd"

            ".local/share/Vial"

            # adb keypair kept; sdk cache + debug.keystore stay ephemeral
            ".local/share/android/.android"

            ".local/share/mcp-trader"
            ".local/share/music-get"
            ".local/share/polybot"
            ".local/share/rtk"
            ".local/share/tirith"
            ".local/share/vibe-kanban"

            ".local/share/superfile"

            ".local/share/crush"
            # .local/share/claude comes from hosts/common/persist.nix

            ".local/share/ai.opencode.desktop"
            ".local/share/app.codeg"
            ".local/share/jean"
            ".local/share/com.jean.desktop"

            ".local/share/com.panes.app"

            ".local/share/com.vercel.cli"
            ".local/share/com.vercel.token"

            ".local/share/syncthing"

            ### ~/.local/state — histories & app state
            ".local/state/bash" # shell history
            ".local/state/zsh" # zsh HISTFILE (modules/core/user/session/xdg.nix)
            ".local/state/nvim" # shada/undo
            ".local/state/pi-harness"
            ".local/state/syncthing" # index
            ".local/state/wireplumber" # audio device volumes

            ".local/state/music-get"
            ".local/state/superfile"
          ]);
      files =
        common.userFiles
        ++ [
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
