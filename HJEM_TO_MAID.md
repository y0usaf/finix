# Hjem to Nix-Maid Migration Plan

## Overview
This document outlines the systematic migration from Hjem to nix-maid for comprehensive dotfile and package management. The migration is organized by complexity and dependencies to ensure smooth transition.

## Migration Strategy

### Phase 1: Infrastructure Setup
**Objective**: Establish nix-maid alongside existing hjem setup

1. **Install nix-maid**
   - Add nix-maid to flake inputs
   - Configure basic nix-maid structure in host configuration
   - Test basic functionality

### Phase 2: Simple Package Modules (Easy - 70% of modules)
**Objective**: Migrate straightforward package installation modules

#### 2.1 Core Packages (Priority: HIGH)
- [ ] `core/packages.nix` → Base system packages
- [ ] `core/user.nix` → User-specific packages

#### 2.2 Programs (Priority: HIGH)
- [ ] `programs/firefox.nix` → Simple package install
- [ ] `programs/discord.nix` → Simple package install  
- [x] `programs/vesktop.nix` → Simple package install
- [ ] `programs/obsidian.nix` → Simple package install
- [ ] `programs/zen-browser.nix` → Simple package install
- [ ] `programs/bluetooth.nix` → Simple package install
- [ ] `programs/creative.nix` → Simple package install
- [ ] `programs/media.nix` → Simple package install
- [ ] `programs/obs.nix` → Simple package install
- [ ] `programs/bambu.nix` → Simple package install
- [ ] `programs/webapps.nix` → Simple package install

#### 2.3 Tools (Priority: HIGH)
- [ ] `tools/7z.nix` → Simple package install
- [ ] `tools/file-roller.nix` → Simple package install
- [ ] `tools/nh.nix` → Simple package install
- [ ] `tools/spotdl.nix` → Simple package install
- [ ] `tools/yt-dlp.nix` → Simple package install

#### 2.4 Gaming Core (Priority: MEDIUM)
- [ ] `gaming/core.nix` → Gaming packages
- [ ] `gaming/controllers.nix` → Controller support

### Phase 3: Configuration Modules (Moderate - 25% of modules)
**Objective**: Migrate modules with configuration files and computed values

#### 3.1 Development Tools (Priority: HIGH)
- [ ] `dev/cursor-ide.nix` → Package + config files
- [ ] `dev/claude-code.nix` → Package + config files
- [ ] `dev/docker.nix` → Package + config files
- [ ] `dev/latex.nix` → Package + config files
- [ ] `dev/npm.nix` → Package + config files
- [ ] `dev/python.nix` → Package + config files
- [ ] `dev/nvim.nix` → Package + config files
- [ ] `dev/mcp.nix` → Package + config files
- [ ] `dev/shell-contrib.nix` → Shell integration
- [ ] `dev/shell-integration.nix` → Shell integration

#### 3.2 Tools with Configuration (Priority: HIGH)
- [ ] `tools/git.nix` → Git config + sync scripts (complex)

#### 3.3 Programs with Configuration (Priority: MEDIUM)
- [ ] `programs/mpv.nix` → Media player config
- [ ] `programs/imv.nix` → Image viewer config
- [ ] `programs/pcmanfm.nix` → File manager config
- [ ] `programs/qbittorrent.nix` → Torrent client config
- [ ] `programs/sway-launcher-desktop.nix` → Launcher config
- [ ] `programs/zellij.nix` → Terminal multiplexer config

#### 3.4 Shell Configuration (Priority: HIGH)
- [ ] `shell/zsh.nix` → ZSH configuration

### Phase 4: Complex UI Modules (Complex - 5% of modules)
**Objective**: Migrate sophisticated UI configurations with computed values

#### 4.1 Core UI Infrastructure (Priority: HIGH)
- [ ] `core/appearance.nix` → Font and theme definitions
- [ ] `core/directories.nix` → XDG directory management
- [ ] `core/defaults.nix` → Default applications

#### 4.2 UI Components (Priority: HIGH)
- [ ] `ui/foot.nix` → Terminal with computed font config
- [ ] `ui/gtk.nix` → GTK theming with DConf integration
- [ ] `ui/wallust.nix` → Wallpaper management
- [ ] `ui/wayland.nix` → Wayland utilities
- [ ] `ui/ags.nix` → AGS configuration

#### 4.3 Hyprland (Priority: CRITICAL - Most Complex)
- [ ] `ui/hyprland/core.nix` → Base Hyprland config
- [ ] `ui/hyprland/options.nix` → Hyprland options
- [ ] `ui/hyprland/monitors.nix` → Monitor configuration
- [ ] `ui/hyprland/keybindings.nix` → Keybinding management
- [ ] `ui/hyprland/window-rules.nix` → Window rules
- [ ] `ui/hyprland/ags-integration.nix` → AGS integration
- [ ] `ui/hyprland/config.nix` → Main config generator
- [ ] `ui/hyprland.nix` → Module wrapper

### Phase 5: Gaming Configurations (Priority: LOW)
**Objective**: Migrate game-specific configurations

#### 5.1 Emulation (Priority: LOW)
- [ ] `gaming/emulation/cemu.nix` → Wii U emulator
- [ ] `gaming/emulation/dolphin.nix` → GameCube/Wii emulator

#### 5.2 Game Configurations (Priority: LOW)
- [ ] `gaming/balatro/installation.nix` → Game setup
- [ ] `gaming/marvel-rivals/engine.nix` → Game engine config
- [ ] `gaming/marvel-rivals/gameusersettings.nix` → Game settings
- [ ] `gaming/marvel-rivals/marvelusersettings.nix` → Game settings
- [ ] `gaming/wukong/engine.nix` → Game engine config

## Migration Mapping

### Hjem → Nix-Maid Structure Conversion

```nix
# BEFORE (Hjem)
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.hjome.programs.example;
in {
  options.cfg.hjome.programs.example = {
    enable = lib.mkEnableOption "example program";
  };

  config = lib.mkIf cfg.enable {
    packages = with pkgs; [ example-package ];
    
    files.".config/example/config".text = ''
      setting = value
    '';
  };
}

# AFTER (Nix-Maid)
users.users.y0usaf.maid = {
  packages = with pkgs; [ example-package ];
  
  file.xdg_config."example/config".text = ''
    setting = value
  '';
};
```

### Key Conversion Patterns

1. **Package Installation**:
   - `packages = [...]` → `packages = [...]` (same)

2. **Configuration Files**:
   - `files.".config/app/config".text` → `file.xdg_config."app/config".text`
   - `files.".local/share/app/data".text` → `file.xdg_data."app/data".text`
   - `files.".zshrc".text` → `file.home.".zshrc".text`

3. **Mustache Variables**:
   - Hardcoded paths → `{{xdg_config_home}}/app/config`
   - User references → `{{user}}`, `{{home}}`

4. **Computed Configurations**:
   - Move complex logic to nix expressions
   - Use nix-maid's templating for dynamic paths

## Implementation Steps

### Step 1: Setup Nix-Maid Infrastructure
```nix
# In flake.nix inputs
nix-maid.url = "github:viperML/nix-maid";

# In host configuration
users.users.y0usaf.maid = {
  # Start with empty config
  packages = [];
};
```

### Step 2: Migrate Simple Modules
- Convert package-only modules first
- Test each category before moving to next

### Step 3: Handle Configuration Files
- Use mustache syntax for portability
- Convert file paths to nix-maid structure

### Step 4: Complex Modules
- Break down complex modules into smaller parts
- Test Hyprland configuration generation carefully

### Step 5: Cleanup
- Remove hjem modules after successful migration
- Update host configurations to remove hjem references

## Testing Strategy

1. **Parallel Testing**: Keep hjem running while testing nix-maid modules
2. **Incremental Validation**: Test each phase before proceeding
3. **Rollback Plan**: Maintain ability to revert to hjem if needed
4. **Dry Runs**: Use `nh os switch --dry` for all tests

## Success Criteria

- [ ] All packages installed correctly
- [ ] All configuration files generated properly
- [ ] Hyprland configuration works identically
- [ ] No functionality regression
- [ ] Cleaner, more maintainable configuration
- [ ] Improved portability with mustache templating

## Notes

- **Backup**: Create git branch before starting migration
- **Dependencies**: Some modules depend on `hostHjem` configurations
- **Complexity**: Hyprland module is most complex - save for last
- **Testing**: Test thoroughly at each phase
- **Documentation**: Update any references to old module paths

## Estimated Timeline

- **Phase 1**: 1 day (setup)
- **Phase 2**: 2-3 days (simple modules)
- **Phase 3**: 3-4 days (configuration modules)
- **Phase 4**: 5-7 days (complex UI modules)
- **Phase 5**: 1-2 days (gaming configurations)
- **Total**: 12-17 days (working incrementally)

---

*This migration plan ensures systematic, safe transition from hjem to nix-maid while maintaining full functionality throughout the process.*