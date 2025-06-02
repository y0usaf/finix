###############################################################################
# SkyFactory 5 Server Configuration
# Simple declarative server setup - just add your modpack URL!
###############################################################################
{
  config,
  lib,
  pkgs,
  nix-minecraft,
  ...
}: let
  cfg = config.hjem.gaming.minecraft.servers.skyfactory5;
in {
  imports = [
    nix-minecraft.nixosModules.minecraft-servers
  ];

  options.hjem.gaming.minecraft.servers.skyfactory5 = {
    enable = lib.mkEnableOption "SkyFactory 5 Minecraft Server";

    # Simple modpack configuration - just paste your URL here!
    modpack = {
      url = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "https://github.com/yourusername/skyfactory5-packwiz/raw/main/pack.toml";
        description = ''
          URL to your packwiz-converted SkyFactory 5 modpack.
          Leave empty to skip modpack installation.
          
          To convert SkyFactory 5:
          1. Download SkyFactory 5 from CurseForge
          2. Run: packwiz curseforge import skyfactory5.zip
          3. Host the result on GitHub/GitLab
          4. Paste the pack.toml URL here
        '';
      };

      hash = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "sha256-L5RiSktqtSQBDecVfGj1iDaXV+E90zrNEcf4jtsg+wk=";
        description = ''
          SHA256 hash of the modpack.
          Get this by running: nix run github:Infinidoge/nix-minecraft#nix-packwiz-prefetch -- <your-url>
          Or leave empty and Nix will tell you the correct hash on first build.
        '';
      };
    };

    # Server settings
    port = lib.mkOption {
      type = lib.types.port;
      default = 25565;
      description = "Server port";
    };

    maxPlayers = lib.mkOption {
      type = lib.types.ints.positive;
      default = 10;
      description = "Maximum number of players";
    };

    motd = lib.mkOption {
      type = lib.types.str;
      default = "SkyFactory 5 Server - Powered by NixOS!";
      description = "Server message of the day";
    };

    difficulty = lib.mkOption {
      type = lib.types.enum ["peaceful" "easy" "normal" "hard"];
      default = "normal";
      description = "Server difficulty";
    };

    jvmOpts = lib.mkOption {
      type = lib.types.str;
      default = "-Xms4G -Xmx8G -XX:+UseG1GC";
      description = "JVM options for the server";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the server port in the firewall";
    };

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to start the server automatically on boot";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/minecraft/SkyFactory5";
      description = "Directory to store server data";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure nix-minecraft overlay is available
    nixpkgs.overlays = [nix-minecraft.overlay];

    # Configure the server
    services.minecraft-servers = {
      enable = true;
      eula = true;
      
      servers.skyfactory5 = {
        enable = true;
        
        # Use Fabric for SkyFactory 5 (Minecraft 1.20.1)
        package = nix-minecraft.packages.${pkgs.system}.fabric-server.override {
          version = "1.20.1";
          loaderVersion = "0.14.24";
        };
        
        # Basic server properties
        serverProperties = {
          server-port = cfg.port;
          max-players = cfg.maxPlayers;
          motd = cfg.motd;
          difficulty = {
            peaceful = 0;
            easy = 1;
            normal = 2;
            hard = 3;
          }.${cfg.difficulty};
          gamemode = "survival";
          level-type = "flat"; # Skyblock/flat world
          spawn-protection = 0;
          enable-command-block = true;
          op-permission-level = 4;
        };

        # JVM configuration
        jvmOpts = cfg.jvmOpts;

        # Modpack integration (only if URL is provided)
        symlinks = lib.mkIf (cfg.modpack.url != "" && cfg.modpack.hash != "") (
          let
            modpack = nix-minecraft.lib.fetchPackwizModpack {
              url = cfg.modpack.url;
              packHash = cfg.modpack.hash;
            };
          in {
            "mods" = "${modpack}/mods";
            "config" = "${modpack}/config";
            # Add other modpack directories as they exist
          } // lib.optionalAttrs (builtins.pathExists "${modpack}/kubejs") {
            "kubejs" = "${modpack}/kubejs";
          } // lib.optionalAttrs (builtins.pathExists "${modpack}/defaultconfigs") {
            "defaultconfigs" = "${modpack}/defaultconfigs";
          }
        );

        # Custom data directory
        dataDir = cfg.dataDir;
      };
    };

    # Firewall configuration
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];

    # Auto-start configuration
    systemd.services.minecraft-server-skyfactory5 = lib.mkIf cfg.autoStart {
      wantedBy = ["multi-user.target"];
    };

    # User configuration
    users.users.minecraft = {
      description = "Minecraft server user";
      group = "minecraft";
      isSystemUser = true;
      createHome = true;
      home = "/var/lib/minecraft";
    };
    users.groups.minecraft = {};

    # Directory permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 minecraft minecraft -"
      "d ${cfg.dataDir}/mods 0755 minecraft minecraft -"
      "d ${cfg.dataDir}/config 0755 minecraft minecraft -"
      "d ${cfg.dataDir}/world 0755 minecraft minecraft -"
    ];
  };
}