{lib, ...}: let
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
    shared = mkOption {
      type = types.attrsOf (types.listOf types.str);
      description = "Shared persistence paths, extended by host policy.";
      default = {
        systemDirectories = [
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/var/log"
          "/etc/ssh"
          "/etc/NetworkManager/system-connections"
          "/var/lib/NetworkManager"
          "/var/lib/tailscale"
          "/var/lib/manzil"
        ];

        systemFiles = [
          "/etc/machine-id"
        ];

        userDirectories = [
          "Dev"
          "Documents"
          "Tokens"
          "nixos"
          ".ssh"
          ".fx"
          ".omfx"
          ".mozilla"
          ".librewolf"
          ".local/share/pi"
          ".config/gh"
          ".config/gws"
          ".config/librewolf"
          ".config/glide"
          ".local/state/nix"
          ".config/pi/agent"
          ".config/codex"
          ".local/share/android"
          ".config/claude"
          ".local/share/azure"
          ".local/state/bash"
        ];

        userFiles = [];
      };
    };
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
}
