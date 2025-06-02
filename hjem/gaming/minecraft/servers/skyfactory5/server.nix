# SkyFactory 5 Server - Simple and Working
{
  config,
  lib,
  pkgs,
  nix-minecraft,
  ...
}: let
  cfg = config.cfg.hjome.gaming.minecraft.servers.skyfactory5;
in {
  imports = [
    nix-minecraft.nixosModules.minecraft-servers
  ];

  # Enable nix-minecraft overlay
  nixpkgs.overlays = [nix-minecraft.overlay];

  config = lib.mkIf cfg.enable {
    # Basic minecraft server setup
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
        
        # Basic server settings
        serverProperties = {
          server-port = 25565;
          max-players = 10;
          motd = "SkyFactory 5 Server";
          difficulty = 2; # normal
          gamemode = "survival";
          level-type = "flat";
          spawn-protection = 0;
          enable-command-block = true;
        };

        # JVM settings
        jvmOpts = "-Xms4G -Xmx8G -XX:+UseG1GC";
        
        # Server data directory
        dataDir = "/var/lib/minecraft/skyfactory5";
      };
    };

    # Create minecraft user
    users.users.minecraft = {
      description = "Minecraft server user";
      group = "minecraft";
      isSystemUser = true;
      createHome = true;
      home = "/var/lib/minecraft";
    };
    users.groups.minecraft = {};

    # Create directories
    systemd.tmpfiles.rules = [
      "d /var/lib/minecraft/skyfactory5 0755 minecraft minecraft -"
    ];
  };
}