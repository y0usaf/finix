# Simple Balatro Mod Configuration

Much cleaner now! Just specify a list of mod names.

## Basic Usage

```nix
{
  cfg.programs.gaming.balatro = {
    enable = true;
    enableLovelyInjector = true;  # Required for mod loading
    enabledMods = [ "talisman" "cryptid" "multiplayer" "cardsleeves" ];
  };
}
```

That's it! No complex nested configuration.

## Lovely Injector

The **Lovely Injector** is a runtime lua injector for LÖVE 2D games that enables mod loading in Balatro. It's **required** for most Balatro mods to work.

When enabled, it automatically:
- Downloads the latest release from [ethangreen-dev/lovely-injector](https://github.com/ethangreen-dev/lovely-injector)
- Extracts `version.dll` from the Windows release
- Installs it to your Balatro game directory

**Important**: You must set `enableLovelyInjector = true` for mods to work!

## Available Mods

Just reference these by name in your `enabledMods` list:

### Repository Mods (full repos)
- **`talisman`** - SpectralPack/Talisman
- **`cryptid`** - SpectralPack/Cryptid  
- **`multiplayer`** - Balatro-Multiplayer/BalatroMultiplayer
- **`cardsleeves`** - larswijn/CardSleeves

### Single File Mods
- **`morespeeds`** - MoreSpeeds.lua (game speed options)
- **`overlay`** - BalatrOverlay.lua (overlay functionality)

## Examples

### Enable all mods:
```nix
cfg.programs.gaming.balatro = {
  enable = true;
  enableLovelyInjector = true;
  enabledMods = [ "talisman" "cryptid" "multiplayer" "cardsleeves" "morespeeds" "overlay" ];
};
```

### Enable only specific mods:
```nix
cfg.programs.gaming.balatro = {
  enable = true;
  enableLovelyInjector = true;
  enabledMods = [ "talisman" "multiplayer" ];
};
```

### Just the injector (no mods):
```nix
cfg.programs.gaming.balatro = {
  enable = true;
  enableLovelyInjector = true;
  enabledMods = [ ];
};
```

### Disable auto-update:
```nix
cfg.programs.gaming.balatro = {
  enable = true;
  enableLovelyInjector = true;
  enabledMods = [ "talisman" "cryptid" ];
  autoUpdate = false;  # Manual updates only
};
```

## Manual Commands

- **Update mods**: `update-balatro-mods`
- **Check mods**: `ls ~/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods`

## Adding New Mods

To add new mods to the available list, edit `mods.nix` and add entries to the `allMods` attribute set. Then users can reference them by name in their `enabledMods` list.

Much simpler! 🎮