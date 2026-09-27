{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
  directory = types.either types.str (types.submodule {
    options = {
      directory = mkOption {type = types.str;};
      mode = mkOption {
        type = types.str;
        default = "0755";
      };
    };
  });
  paths = {
    directories = mkOption {
      type = types.listOf directory;
      default = [];
    };
    files = mkOption {
      type = types.listOf types.str;
      default = [];
    };
  };
in {
  options.finix.persistence = {
    allowlist = mkOption {
      description = "Host persistence policy consumed by native Finix mount modules.";
      default = {};
      type = types.submodule {
        options =
          paths
          // {
            hideMounts = mkOption {
              type = types.bool;
              default = true;
            };
            users = mkOption {
              type = types.attrsOf (types.submodule {options = paths;});
              default = {};
            };
          };
      };
    };
  };

  config.finix.persistence.allowlist = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/etc/ssh"
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"
      "/var/lib/manzil"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/tailscale"
      "/var/log"
    ];
    files = ["/etc/machine-id"];
    users.${config.user.name} = {
      directories = [
        ".azure"
        ".cache/mesa_shader_cache"
        ".cache/nix"
        ".cache/nv"
        ".config/AionUi"
        ".config/Frame"
        ".config/GitHub Desktop"
        ".config/Hermes"
        ".config/Mullvad VPN"
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
        ".config/nushell"
        ".config/slskd"
        ".config/snowflake"
        ".cookunity"
        ".cursor/sand"
        ".cursor/sand-dev"
        ".hermes"
        ".local/share/Vial"
        ".local/share/app.codeg"
        ".local/share/applications"
        ".local/share/azure"
        ".local/share/com.jean.desktop"
        ".local/share/com.pais.handy"
        ".local/share/com.panes.app"
        ".local/share/gnupg"
        ".local/share/handy"
        ".local/share/icons"
        ".local/share/keyrings"
        ".local/share/mcp-trader"
        ".local/share/music-get"
        ".local/share/pki"
        ".local/share/polybot"
        ".local/share/slskd"
        ".local/share/superfile"
        ".local/share/vibe-kanban"
        ".local/state/bash"
        ".local/state/manzil"
        ".local/state/music-get"
        ".local/state/nix"
        ".local/state/superfile"
        ".mcp-auth"
        ".mozilla"
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
      files = [".SNOW"];
    };
  };
}
