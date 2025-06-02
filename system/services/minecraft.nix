# SkyFactory 5 Server - Direct system configuration
{
  pkgs,
  nix-minecraft,
  ...
}: {
  imports = [
    nix-minecraft.nixosModules.minecraft-servers
  ];

  nixpkgs.overlays = [nix-minecraft.overlay];

  services.minecraft-servers = {
    enable = true;
    eula = true;
    
    servers.skyfactory5 = {
      enable = true;
      
      package = nix-minecraft.packages.${pkgs.system}.fabric-server.override {
        version = "1.20.1";
        loaderVersion = "0.14.24";
      };
      
      serverProperties = {
        server-port = 25565;
        max-players = 10;
        motd = "SkyFactory 5 Server";
        difficulty = 2;
        gamemode = "survival";
        level-type = "flat";
        spawn-protection = 0;
        enable-command-block = true;
      };

      jvmOpts = "-Xms4G -Xmx8G -XX:+UseG1GC";
      dataDir = "/var/lib/minecraft/skyfactory5";
    };
  };

  users.users.minecraft = {
    description = "Minecraft server user";
    group = "minecraft";
    isSystemUser = true;
    createHome = true;
    home = "/var/lib/minecraft";
  };
  users.groups.minecraft = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/minecraft/skyfactory5 0755 minecraft minecraft -"
  ];
}