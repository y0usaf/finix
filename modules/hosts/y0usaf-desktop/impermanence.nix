{
  config,
  lib,
  ...
}: let
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
  finix.persistence.allowlist = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/log"

      "/etc/ssh"

      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager"
      "/var/lib/tailscale"

      "/var/lib/manzil"

      {
        directory = "/root";
        mode = "0700";
      }

      "/var/lib/sbctl"

      "/var/lib/bluetooth"

      "/var/lib/docker"

      "/var/lib/btrbk"
    ];
    files = [
      "/etc/machine-id"
    ];
    users.y0usaf = {
      directories =
        [
          ".config/pi/agent"
          ".config/claude"
          ".cache/nv"
          ".local/share/android"
          ".config/codex"
          "Documents"
          "Tokens"
          "finix"
          "Downloads"
          "Desktop"
          "Videos"
          "Games"
          "cu-workbench"
          "inscend"

          ".config/AionUi"
          ".config/manicode"
          ".config/agent-harness"
          ".config/herdr"

          ".config/camset"

          ".ssh"
          ".azure"
          ".pki"
          ".aws"
          ".mcp-auth"

          ".config/silvabot"
          ".local/share/silvabot"
          ".local/state/silvabot"

          ".cursor/sand-dev"
          ".cursor/sand"
          ".grokbot"

          ".fx"
          ".omfx"
          ".pi"
          ".omp"
          ".prime"
          ".hermes"
          ".crush"
          ".cookunity"
          ".phi"
          ".paseo"
          ".slack"
          ".supabase"
          ".n8n-mcp"
          ".obsidian"

          ".config/firefox"
          ".librewolf"
          ".config/glide"
          ".config/discord"
          ".config/vesktop"
          ".config/Vencord"

          ".steam"
          ".SteamCloud"
          ".stremio-server"
          ".slskd"

          ".config/gh"
          ".config/gws"
          ".config/age"
          ".config/aws"
          ".config/gcloud"

          ".config/Slack/Local Storage"
          ".config/Slack/Session Storage"
          ".config/Slack/IndexedDB"
          ".config/Slack/storage"

          ".config/syncthing"

          ".config/Claude"
          ".config/Hermes"
          ".config/Codex"
          ".config/opencode"
          ".config/pi-harness"
          ".config/crush"
          ".config/phi"

          ".config/obsidian"
          ".config/obs-studio"
          ".config/qBittorrent"
          ".config/stoat-desktop"
          ".config/slskd"
          ".config/epy"
          ".config/cmus"
          ".config/GitHub Desktop"

          ".config/gws-inscend"
          ".config/Frame"
          ".config/intent"
          ".config/ramp"
          ".config/snowflake"

          ".config/Cemu"
          ".config/unity3d"
          ".config/bolt-launcher"

          ".config/dconf"
          ".config/nix"
          ".config/ekko"

          ".cache/ekko"

          ".local/share/gnupg"
          ".local/share/keyrings"
          ".local/share/pki"

          ".local/share/PrismLauncher"
          ".local/share/bun"
          ".local/share/cargo"
          ".local/share/rustup"
          ".local/share/opencode"
          ".local/share/phi"
          ".local/share/nvim"
        ]
        ++ builtins.map (n: ".local/share/${n}") gameSaves
        ++ lib.optionals config.user.gaming.core.enable [
          ".barony"
          ".local/share/Ultrapool"
          ".local/share/godot/app_userdata"
        ]
        ++ [
          ".local/share/stremio"
          ".local/share/stremio-linux-shell"
          ".local/share/slskd"
          ".local/share/Vial"

          ".local/share/android/.android"
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

          ".local/state/nix"
          ".local/state/bash"
          ".local/state/rush"
          ".local/state/nvim"
          ".local/state/pi-harness"
          ".local/state/syncthing"
          ".local/state/wireplumber"
          ".local/state/music-get"
          ".local/state/superfile"

          ".cache/nix"
        ];
      files = [
        ".npmrc"

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
