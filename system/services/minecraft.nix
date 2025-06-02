# SkyFactory 5 Server - Simple working configuration
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
      package = pkgs.fabricServers.fabric-1_20_1;
      
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
    };
  };
}