# ALSO the finix system's persist allowlist: finix/hosts/y0usaf-desktop/*
# calls this function and replays these lists as plain bind mounts. Keep it
# pure literals (no lib/pkgs/config) so both module universes can read it.
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
        # NOTE: DCIM, Music, Pictures, .local/share/Steam are dedicated
        # btrfs subvols mounted on top of /home — NOT listed here.
        # @config/@local were dissolved into the granular allowlists below;
        # anything not listed is ephemeral (recoverable from
        # /btrfs/_premigration/* snapshots until those are deleted).

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

        ### ~/.config — mutable app state only. Nix/manzil-generated configs
        ### (zsh, nushell rc, niri, foot, wallust, gtk, mpv, git, gh config,
        ### npm/bun/docker/python rc, pi, mangohud, ...) regenerate on switch.

        # Credentials / identity
        ".config/age"
        ".config/aws"
        ".config/gcloud"
        ".config/gh" # hosts.yml oauth
        ".config/ngrok"

        # Browsers
        ".config/chromium"
        ".config/librewolf"
        ".config/net.imput.helium"

        # Chat / comms (bulk = cache; sessions live inside)
        ".config/discord"
        ".config/discordcanary"
        ".config/vesktop"
        ".config/Vencord" # mutable settings/quickCss; themes regen
        ".config/Slack"

        # Sync (device keys + index — critical)
        ".config/syncthing"

        # AI / editors / IDEs
        ".config/AionUi"

        ".config/Claude"
        ".config/Codex"
        ".config/opencode"
        ".config/manicode"
        ".config/agent-harness"
        ".config/pi-harness"
        ".config/jcode"
        ".config/crush"
        ".config/phi"

        # Desktop apps
        ".config/obsidian"
        ".config/obs-studio"
        ".config/BambuStudio"
        ".config/OrcaSlicer"
        ".config/GIMP"
        ".config/Pinta"

        ".config/stoat-desktop"
        ".config/qBittorrent"
        ".config/nicotine"
        ".config/slskd"
        ".config/Logseq"
        ".config/Ladybird"
        ".config/epy"
        ".config/cmus" # library/playlists

        ".config/GitHub Desktop"

        # Work
        ".config/gws"
        ".config/gws-inscend"

        ".config/Frame"
        ".config/intent"
        ".config/herdr"
        ".config/kopuz"
        ".config/snowflake"
        ".config/camset"

        # Gaming
        ".config/Cemu"
        ".config/unity3d" # game prefs
        ".config/bolt-launcher"
        ".config/Olympus"

        # Misc state
        ".config/dconf"
        ".config/nix" # possible access-tokens
        ".config/nushell" # generated rc clobbers; history.sqlite persists
        ".config/ekko" # config.toml + extensions (app-owned)

        ### ~/.local/share — real data/saves. Caches (go, gradle, pnpm, uv,
        ### NuGet, yarn, pyenv, virtualenv, Trash, ...) are ephemeral.

        # Keys / identity
        ".local/share/gnupg"
        ".local/share/keyrings"
        ".local/share/pki"

        # Big data (flagged: prune candidates, but keep)
        ".local/share/PrismLauncher" # 55G — minecraft worlds, irreplaceable
        ".local/share/bun" # globals only (supabase/vercel/...); install/cache purged, regenerates
        ".local/share/vicinae" # 7.5G — clipboard/extension db; PRUNE candidate
        ".local/share/cargo"
        ".local/share/rustup"
        ".local/share/npm" # global prefix
        ".local/share/containers" # podman
        ".local/share/opencode"

        ".local/share/phi"

        # Emulation / gaming (saves!)
        ".local/share/dolphin-emu"
        ".local/share/yuzu"
        ".local/share/sudachi"
        ".local/share/Cemu"
        ".local/share/shipofharkinian"
        ".local/share/bolt-launcher"
        ".local/share/lutris"
        ".local/share/gale"
        ".local/share/com.kesomannen.gale"
        ".local/share/NexusMods.App"
        ".local/share/osu"
        ".local/share/wine"
        ".local/share/skua-wine"
        ".local/share/godot"
        ".local/share/PixelOver"
        ".local/share/balatroai"
        ".local/share/Celeste"
        ".local/share/CassetteBeasts"
        ".local/share/Brotato"
        ".local/share/Baba_Is_You"
        ".local/share/binding of isaac rebirth"
        ".local/share/HallsOfTorment"
        ".local/share/YourOnlyMoveIsHUSTLE"
        ".local/share/Rocket League"
        ".local/share/SteamWorld Heist"
        ".local/share/shapez.io"
        ".local/share/lootplot"
        ".local/share/love"
        ".local/share/pokete"
        ".local/share/hackerpg"
        ".local/share/com.overboy.noobsarecoming"
        ".local/share/Noobs Are Coming (Save)"
        ".local/share/.renpy"
        ".local/share/.Wurst encryption"
        ".local/share/aspyr-media"
        ".local/share/Smart Code ltd"
        ".local/share/CO-E33_Save_Editor"
        ".local/share/com.co-e33-save-editor.app"

        # Apps
        ".local/share/TelegramDesktop"
        ".local/share/whatsapp-for-linux"
        ".local/share/wasistlos"
        ".local/share/zoom"
        ".local/share/stremio"
        ".local/share/qBittorrent" # BT_backup resume data
        ".local/share/nicotine"
        ".local/share/slskd"
        ".local/share/qutebrowser"
        ".local/share/Ladybird"

        ".local/share/nvim" # plugins/mason
        ".local/share/mpd"
        ".local/share/Anki2"
        ".local/share/komikku"
        ".local/share/manga-tui"
        ".local/share/zathura"
        ".local/share/qalculate"
        ".local/share/jrnl"
        ".local/share/weechat"
        ".local/share/zoxide"
        ".local/share/waydroid"
        ".local/share/handy"
        ".local/share/com.pais.handy" # whisper models
        ".local/share/whisper-models"
        ".local/share/FreeCAD"
        ".local/share/Meltytech"
        ".local/share/bambu-studio"
        ".local/share/bambustudio"
        ".local/share/orca-slicer"
        ".local/share/Vial"
        ".local/share/wootomation"
        ".local/share/fonts"
        ".local/share/icons"
        ".local/share/sounds"
        ".local/share/applications"
        ".local/share/android"
        ".local/share/jupyter"
        ".local/share/mcp-trader"
        ".local/share/music-get"
        ".local/share/polybot"
        ".local/share/rtk"
        ".local/share/tirith"
        ".local/share/vibe-kanban"
        ".local/share/supermaven"
        ".local/share/smassh"
        ".local/share/superfile"
        ".local/share/parllama"
        ".local/share/charm"
        ".local/share/crush"
        ".local/share/claude"
        ".local/share/piebald"
        ".local/share/ai.piebald.desktop"
        ".local/share/ai.opencode.desktop"
        ".local/share/app.codeg"
        ".local/share/jean"
        ".local/share/com.jean.desktop"

        ".local/share/com.panes.app"

        ".local/share/com.vercel.cli"
        ".local/share/com.vercel.token"
        ".local/share/kopuz"

        ".local/share/syncthing"

        ### ~/.local/state — histories & app state
        ".local/state/zsh" # shell history
        ".local/state/bash"
        ".local/state/elvish"
        ".local/state/nix"
        ".local/state/nvim" # shada/undo
        ".local/state/codex"
        ".local/state/opencode"
        ".local/state/agent-harness"
        ".local/state/pi-harness"
        ".local/state/pi-rs-parallel"
        ".local/state/ekko-pi"
        ".local/state/ekko-parallel"
        ".local/state/syncthing" # index
        ".local/state/wireplumber" # audio device volumes

        ".local/state/lazygit"
        ".local/state/manzil"
        ".local/state/bayt"
        ".local/state/herdr"
        ".local/state/sayl"

        ".local/state/music-get"
        ".local/state/NexusMods.App"
        ".local/state/spicetify"
        ".local/state/superfile"
        ".local/state/vicinae"
        ".local/state/weechat"
        ".local/state/zap"

        # Caches worth keeping (shader/compile caches; .cache itself ephemeral)
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
        ".SNOW"
      ];
    };
  };
}
