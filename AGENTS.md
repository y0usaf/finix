# NixOS Configuration Repository - Agent Guide

This document provides comprehensive guidance for AI agents working with this NixOS configuration repository.

## Repository Overview

This is a **npins-based NixOS configuration** using **hjem** for home management, designed for a desktop system with NVIDIA GPU, Hyprland compositor, and comprehensive development tools.

### Key Architecture Decisions

- **Package Management**: npins (NOT flakes) for dependency management
- **Home Management**: hjem (NOT home-manager) for user files and packages
- **Build System**: nh for system operations
- **Compositor**: Hyprland with AGS/Quickshell integration
- **Development**: Full AI/ML stack with CUDA support

## Directory Structure

```
├── configs/                    # Host and user configurations
│   ├── hosts/y0usaf-desktop/   # Host-specific settings
│   └── users/                  # User-specific configurations
├── lib/                        # Core library functions and builders
│   ├── builders/               # NixOS configuration builders
│   ├── generators/             # Config file generators (KDL, Hyprland)
│   ├── overlays/               # Package overlays and extensions
│   └── scripts/                # Utility scripts
├── modules/                    # NixOS modules
│   ├── home/                   # User-space modules (hjem-based)
│   └── system/                 # System-level modules
├── npins/                      # Dependency management
│   ├── sources.json            # Pinned source definitions
│   └── default.nix             # Source imports
├── flake.nix                   # Minimal flake wrapper
└── AGENTS.md                   # This file
```

## Core Protocols

### 1. Package Management Protocol

**Use npins, NOT flakes for dependencies:**

```bash
# Add new dependency
npins add github owner repo

# Update specific dependency
npins update dependency-name

# Update all dependencies
npins update
```

**Never modify flake.nix** - it's a minimal wrapper. All real configuration happens through npins.

### 2. Home Management Protocol

**Use hjem for all user-space configuration:**

```nix
# ✅ Correct - hjem pattern
hjem.users.${config.user.name} = {
  packages = with pkgs; [ package1 package2 ];
  files = {
    ".config/app/config.toml" = {
      text = "configuration content";
      clobber = true;
    };
  };
};

# ❌ Wrong - don't use home-manager
home-manager.users.${config.user.name} = { ... };

# ❌ Wrong - don't use nix-maid (removed)
users.users.${config.user.name}.maid = { ... };
```

**System services remain at system level:**

```nix
# ✅ Correct - system-level services
systemd.user.services.my-service = { ... };
systemd.tmpfiles.rules = [ ... ];

# ❌ Wrong - hjem doesn't handle services
hjem.users.${name}.systemd.services = { ... };
```

### 3. Build Protocol

**Always use nh for system operations:**

```bash
# Format code
alejandra .

# Dry build (test)
nh os switch --dry

# Build and switch
nh os switch

# Clean old generations
nh clean all
```

**Never use nixos-rebuild directly** - nh provides better UX and error handling.

### 4. Module Development Protocol

**Follow the established patterns:**

```nix
# Standard module template
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.category.module-name;
in {
  options.home.category.module-name = {
    enable = lib.mkEnableOption "description";
    # Additional options...
  };

  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = with pkgs; [ ... ];
      files = { ... };
    };
    
    # System-level config if needed
    systemd.user.services = { ... };
  };
}
```

### 5. Configuration File Generation

**Use the built-in generators:**

```nix
# For Hyprland configs
lib.generators.toHyprconf { ... }

# For KDL configs (Niri, Zellij)
lib.generators.toKDL { ... }

# For JSON configs
builtins.toJSON { ... }
```

## Development Workflows

### Adding New Software

1. **Determine scope**: User package (hjem) vs system package
2. **Create module** in appropriate `modules/home/` subdirectory
3. **Add to default.nix** in the category
4. **Enable in user config** if needed
5. **Test with dry build**

### Modifying Existing Configuration

1. **Read the existing module** to understand patterns
2. **Follow established conventions** (options, config structure)
3. **Preserve existing functionality** unless explicitly changing
4. **Test changes** with `nh os switch --dry`

### Adding External Dependencies

1. **Use npins**: `npins add github owner repo`
2. **Add to overlays** if package modifications needed
3. **Import in modules** as needed
4. **Update sources.json** gets handled automatically

## Important Conventions

### File Organization

- **modules/home/**: User-space configuration (hjem)
- **modules/system/**: System-level configuration
- **configs/hosts/**: Host-specific settings
- **configs/users/**: User-specific settings
- **lib/**: Reusable functions and builders

### Naming Conventions

- **Module files**: `kebab-case.nix`
- **Options**: `config.home.category.module-name`
- **Variables**: `camelCase` for Nix, `kebab-case` for files
- **Services**: `kebab-case-service-name`

### Code Style

- **Use alejandra** for formatting (automatic)
- **Prefer explicit imports** over `with` statements
- **Use `lib.mkIf`** for conditional configuration
- **Document complex logic** with comments

## System-Specific Information

### Hardware Configuration

- **GPU**: NVIDIA RTX with CUDA support
- **Audio**: PipeWire with low-latency setup
- **Display**: Multi-monitor Hyprland setup
- **Input**: Gaming peripherals with custom configs

### Development Environment

- **AI/ML**: CUDA, Python, Jupyter, various AI tools
- **Languages**: Nix, Python, JavaScript, Rust, Go
- **Editors**: Neovim (primary), Cursor IDE
- **Containers**: Docker, Podman support

### Key Services

- **Compositor**: Hyprland with AGS/Quickshell
- **Terminal**: Foot with custom theming
- **Shell**: Zsh with custom aliases and functions
- **File Manager**: PCManFM with custom actions

## Troubleshooting

### Common Issues

1. **Build failures**: Check `nh os switch --dry` first
2. **Missing packages**: Verify hjem configuration
3. **Service failures**: Check systemd user services
4. **File conflicts**: Ensure proper `clobber = true`

### Debug Commands

```bash
# Check system status
systemctl --user status

# View logs
journalctl --user -u service-name

# Check hjem status
systemctl --user status hjem-*

# Verify configuration
nix-instantiate --eval --expr '(import ./lib).nixosConfigurations'
```

### Recovery Procedures

1. **Rollback**: `sudo nixos-rebuild switch --rollback`
2. **Boot previous generation**: Select in GRUB
3. **Emergency shell**: Boot with `init=/bin/sh`

## Best Practices for AI Agents

### Before Making Changes

1. **Read existing code** to understand patterns
2. **Check related modules** for consistency
3. **Understand the user's workflow** and preferences
4. **Test with dry build** before applying

### When Writing Code

1. **Follow established patterns** religiously
2. **Use existing helper functions** from lib/
3. **Maintain backward compatibility** unless explicitly changing
4. **Add proper error handling** and validation

### After Making Changes

1. **Format with alejandra**
2. **Test dry build**
3. **Verify functionality** if possible
4. **Document significant changes**

## Security Considerations

- **Never commit secrets** to the repository
- **Use proper file permissions** (0600 for sensitive files)
- **Validate external inputs** in modules
- **Follow principle of least privilege**

## Performance Considerations

- **Minimize rebuilds** by structuring changes properly
- **Use `lib.mkIf`** to avoid unnecessary evaluation
- **Cache expensive computations** when possible
- **Profile build times** for complex changes

---

This repository represents a carefully crafted, high-performance NixOS configuration optimized for development work with AI/ML tools. When making changes, prioritize consistency with existing patterns and thorough testing.