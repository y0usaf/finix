{config, ...}: let
  common = config.finix.persistence.shared;
in {
  finix.persistence.allowlist = {
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
        builtins.filter (directory: directory != "Dev" && directory != "nixos") common.userDirectories
        ++ [
          "finix"
          "cu-workbench"
          ".steam"
          ".local/share/android"
          ".cache/nv"
          ".config/pi/agent"
          ".config/codex"
          ".config/claude"
          ".local/share/azure"
          ".local/state/bash"
          ".config/Codex"
          ".config/opencode"
          ".config/pi-harness"
          ".omp"
          ".config/discord"
          ".config/discordcanary"
          ".config/vesktop"
          ".config/Vencord"
          ".config/Slack"
          ".config/syncthing"
          ".config/obsidian"
          ".config/chromium"
          ".config/Pinta"
          ".config/Mullvad VPN"
          ".config/ekko"
          ".config/dconf"
          ".config/nushell"
          ".config/nix"
          ".config/unity3d"
          ".config/bolt-launcher"
          ".local/share/PrismLauncher"
          ".local/share/stremio"
          ".local/share/nvim"
          ".local/share/pki"
          ".local/share/handy"
          ".local/share/com.pais.handy"
          ".local/share/rtk"
          ".local/share/bun"
          ".local/share/cargo"
          ".local/share/rustup"
          ".local/share/com.vercel.cli"
          ".local/share/applications"
          ".local/share/icons"
          ".local/state/codex"
          ".local/state/pi-harness"
          ".local/state/manzil"
          ".local/state/nvim"
          ".local/state/wireplumber"
          ".cache/librewolf"
          ".cache/wallust"
          ".cache/ekko"
          ".cache/mesa_shader_cache"
        ];
      files =
        common.userFiles
        ++ [
          ".npmrc"
        ];
    };
  };
}
