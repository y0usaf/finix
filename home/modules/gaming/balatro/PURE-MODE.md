# Balatro Mods - Pure vs Impure Mode

This module supports two modes for managing Balatro mods:

## Impure Mode (Default)
- **How it works**: Downloads mods at runtime using git clone and curl
- **Pros**: 
  - Easy to update mods (just run `update-balatro-mods`)
  - No need to rebuild system for mod updates
  - Flexible and fast iteration
- **Cons**: 
  - Not reproducible (mods can change between runs)
  - Downloads happen outside Nix store
  - No integrity checking

## Pure Mode
- **How it works**: Fetches all mods through Nix store with pinned versions
- **Pros**: 
  - Fully reproducible builds
  - Integrity checking with SHA256 hashes
  - Mods cached in Nix store
  - Declarative and immutable
- **Cons**: 
  - Requires system rebuild to update mods
  - Need to manually update commit hashes for new versions
  - Slower iteration cycle

## Configuration

### Impure Mode (Default)
```nix
balatro = {
  enable = true;
  pureMode = false;  # or omit (default)
  enableLovelyInjector = true;
  enabledMods = [ "steamodded" "talisman" "cryptid" ];
};
```

### Pure Mode
```nix
balatro = {
  enable = true;
  pureMode = true;
  enableLovelyInjector = true;
  enabledMods = [ "steamodded" "talisman" "cryptid" ];
};
```

## Switching Between Modes

When switching from impure to pure mode:
1. Set `pureMode = true` in your configuration
2. Run `nh os switch --dry` to rebuild
3. The activation script will clean up old impure mods and symlink from Nix store

When switching from pure to impure mode:
1. Set `pureMode = false` (or remove the option)
2. Run `nh os switch --dry` to rebuild
3. Run `update-balatro-mods` to download mods using the impure method

## Updating Mods

### Impure Mode
```bash
update-balatro-mods
```

### Pure Mode
1. Update the commit hashes in `mods-pure.nix`
2. Update the corresponding SHA256 hashes
3. Rebuild your system with `nh os switch --dry`

## Recommendation

- **Use Impure Mode** if you want easy mod updates and don't mind the non-reproducible nature
- **Use Pure Mode** if you prioritize reproducibility and don't mind the extra work for updates