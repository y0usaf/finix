###############################################################################
# SkyFactory 5 Server Example Configuration
# This shows how simple it is to set up a server!
###############################################################################
{
  # Enable Minecraft client (PrismLauncher)
  hjem.gaming.minecraft.enable = true;

  # Enable SkyFactory 5 server
  hjem.gaming.minecraft.servers.skyfactory5 = {
    enable = true;
    
    # Just paste your modpack details here!
    modpack = {
      url = "https://github.com/yourusername/skyfactory5-packwiz/raw/main/pack.toml";
      hash = "sha256-your-hash-here"; # Nix will tell you this on first build
    };
    
    # Server settings
    port = 25565;
    maxPlayers = 10;
    motd = "Welcome to SkyFactory 5!";
    difficulty = "normal";
    jvmOpts = "-Xms4G -Xmx8G -XX:+UseG1GC";
    
    # Convenience options
    openFirewall = true;  # Open port in firewall
    autoStart = true;     # Start on boot
  };
}

###############################################################################
# That's it! Just:
# 1. Add this to your configuration
# 2. Run: nh os switch --dry
# 3. Your server is ready!
#
# To add more servers, just create new folders under servers/ and import them
###############################################################################