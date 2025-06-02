# SkyFactory 5 Server Setup Guide

This guide will help you set up the SkyFactory 5 modpack for your Minecraft server using packwiz for automatic conversion.

## Overview

SkyFactory 5 is a CurseForge modpack. Instead of manually converting mods, we'll use **packwiz** to automatically import the entire modpack, then use nix-minecraft's `fetchPackwizModpack` to handle all mods declaratively.

## Step 1: Install packwiz

First, install packwiz on your system:

```bash
# Install Go if you don't have it
nix-shell -p go

# Install packwiz
go install github.com/packwiz/packwiz@latest

# Make sure it's in your PATH
export PATH=$PATH:$(go env GOPATH)/bin
```

## Step 2: Download SkyFactory 5 Modpack

1. Go to [SkyFactory 5 on CurseForge](https://www.curseforge.com/minecraft/modpacks/skyfactory-5)
2. Click on "Files" tab  
3. Download the **client modpack zip** (not server pack - packwiz works better with client packs)
4. Note the downloaded file path

## Step 3: Convert to packwiz Format (AUTOMATIC!)

This is the magic step - packwiz can automatically import the entire CurseForge modpack:

```bash
# Create a directory for the modpack
mkdir -p ~/skyfactory5-packwiz
cd ~/skyfactory5-packwiz

# Import the CurseForge modpack automatically!
packwiz curseforge import /path/to/skyfactory5.zip

# This will:
# - Extract all mod information
# - Create .pw.toml files for each mod  
# - Set up pack.toml with correct versions
# - Handle dependencies automatically
# - Create a packwiz modpack ready for nix-minecraft!
```

## Step 4: Host the packwiz Modpack

You need to host the packwiz modpack somewhere accessible:

**Option A: Local Git Repository**
```bash
cd ~/skyfactory5-packwiz
git init
git add .
git commit -m "SkyFactory 5 packwiz import"

# Push to GitHub/GitLab/etc.
# Example: git remote add origin https://github.com/yourusername/skyfactory5-packwiz.git
# git push -u origin main
```

**Option B: Use packwiz serve (for testing)**
```bash
cd ~/skyfactory5-packwiz  
packwiz serve
# This serves the modpack at http://localhost:8080
```

## Step 5: Update Your Nix Configuration

Now you can use the automatically converted modpack! Update your `skyfactory5.nix`:

```nix
# In your skyfactory5.nix, replace the manual mod list with:

# SkyFactory 5 modpack (automatically converted from CurseForge)
modpack = nix-minecraft.lib.fetchPackwizModpack {
  url = "https://github.com/yourusername/skyfactory5-packwiz/raw/main/pack.toml";
  packHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Will need to be updated
};
```

## Step 6: Generate the Hash

```bash
# Get the correct hash for your modpack
nix run github:Infinidoge/nix-minecraft#nix-packwiz-prefetch -- https://github.com/yourusername/skyfactory5-packwiz/raw/main/pack.toml
```

Use the output hash in your `modpack` configuration.

## Alternative Tools

If you prefer other tools:

### mc-converter (Python)
```bash
pip install mc-converter
mc-converter -i skyfactory5.zip -f packwiz -o ./converted/
```

### packwiz-wrapper (Enhanced packwiz)
```bash
go install github.com/Merith-TK/packwiz-wrapper/cmd/pw@main
pw import skyfactory5.zip
```

## Benefits of This Approach

✅ **Automatic**: No manual mod-by-mod conversion  
✅ **Dependency Resolution**: Packwiz handles mod dependencies  
✅ **Updates**: Can update the entire modpack with `packwiz update --all`  
✅ **Nix Integration**: Works perfectly with nix-minecraft  
✅ **Reproducible**: Same modpack every time  
✅ **Configurable**: Can modify mods after import  

## Troubleshooting

**Issue: Some mods not available on CurseForge**
- packwiz will place unavailable mods as JARs in the `mods/` folder
- These get included in the modpack automatically

**Issue: Version conflicts**  
- Edit `pack.toml` to adjust acceptable game versions
- Use `packwiz update` to resolve conflicts

**Issue: Optional mods**
- packwiz preserves optional mod settings from the original modpack
- You can modify `.pw.toml` files to change optional status

This approach converts the entire 100+ mod SkyFactory 5 modpack automatically instead of requiring manual conversion of each mod!