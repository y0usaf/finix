# Pure literals (import/++ only, no lib/pkgs/config) so the finix module
# universe could replay these lists as bind mounts. Shared entries live in
# ../common/persist.nix.
_: let
  common = import ../common/persist.nix;
in {
  environment.persistence."/persist" = {
    hideMounts = true;
    directories =
      common.systemDirectories
      ++ [
        "/var/lib/docker"
        "/var/lib/bluetooth"
      ];
    files = common.systemFiles;
    users.y0usaf = {
      directories =
        common.userDirectories
        ++ [
          # NOTE: .local/share/Steam is a dedicated btrfs subvol (@steam)
          # mounted on top of /home — NOT listed here.

          # Gaming
          ".steam"

          # AI / editors
          ".config/claude" # claude-code plugins
          ".config/Codex"
          ".config/opencode"
          ".config/pi-harness"

          # Chat / comms
          ".config/discord"
          ".config/discordcanary"
          ".config/vesktop"
          ".config/Vencord"
          ".config/Slack"

          # Sync (device keys + index — critical)
          ".config/syncthing"

          # Desktop apps
          ".config/obsidian"
          ".config/chromium"
          ".config/Pinta"
          ".config/Mullvad VPN"
          ".config/ekko" # config.toml + extensions (app-owned)
          ".config/dconf"
          ".config/nushell" # generated rc clobbers; history.sqlite persists
          ".config/nix" # possible access-tokens

          # Gaming config
          ".config/unity3d" # game prefs
          ".config/bolt-launcher"

          ### ~/.local/share — real data only. Caches (pnpm, flatpak, Trash,
          ### hyprland, gvfs-metadata, ...) are ephemeral. vicinae deliberately
          ### NOT persisted (clipboard/extension db, rebuildable).
          ".local/share/PrismLauncher" # minecraft worlds
          ".local/share/stremio"
          ".local/share/nvim" # plugins/mason
          ".local/share/pki"
          ".local/share/rtk"
          ".local/share/bun" # globals only; install/cache regenerates
          ".local/share/cargo"
          ".local/share/rustup"
          ".local/share/com.vercel.cli"
          ".local/share/applications"
          ".local/share/icons"

          ### ~/.local/state — histories & app state
          ".local/state/codex"
          ".local/state/pi-harness"
          ".local/state/manzil"
          ".local/state/nvim" # shada/undo
          ".local/state/wireplumber" # audio device volumes

          # Caches worth keeping (shader/compile caches)
          ".cache/librewolf"
          ".cache/wallust"
          ".cache/ekko"
          ".cache/mesa_shader_cache"
        ];
      files = common.userFiles;
    };
  };
}
