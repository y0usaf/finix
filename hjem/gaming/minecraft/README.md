# Minecraft Gaming Module

This module provides both client-side Minecraft support via PrismLauncher and declarative server configurations.

## Structure

```
minecraft/
├── default.nix              # Main module imports
├── installation.nix         # PrismLauncher and client setup
├── servers/                 # Server configurations
│   └── skyfactory5/         # SkyFactory 5 server
│       ├── default.nix      # Imports server.nix
│       ├── server.nix       # Server configuration
│       ├── example.nix      # Usage example
│       └── SETUP.md         # Setup instructions
└── README.md               # This file
```

## Quick Start

### 1. Enable Minecraft Client
```nix
{
  hjem.gaming.minecraft.enable = true;
}
```
This installs PrismLauncher with multiple Java versions.

### 2. Add a Server
```nix
{
  hjem.gaming.minecraft.servers.skyfactory5 = {
    enable = true;
    modpack = {
      url = "https://your-github.com/skyfactory5-packwiz/raw/main/pack.toml";
      hash = "sha256-your-hash-here";
    };
    openFirewall = true;
    autoStart = true;
  };
}
```

## Adding New Servers

1. Create a new folder under `servers/`
2. Add `default.nix` that imports your server configuration
3. Create your server module following the skyfactory5 pattern
4. Import it in your host configuration

## Features

- **Declarative**: Just specify a modpack URL and everything is handled
- **Multiple Java versions**: Automatic support for different MC versions  
- **Firewall integration**: Automatic port opening
- **Systemd integration**: Proper service management
- **Modular**: Each server is its own module
- **Clean structure**: Follows the same pattern as other hjem modules

## Modpack Setup

For modpack servers, you'll need to:
1. Convert your modpack to packwiz format (see individual server SETUP.md files)
2. Host the converted modpack on GitHub/GitLab
3. Specify the URL and hash in your configuration

The system handles all mod downloading, dependency resolution, and server setup automatically.