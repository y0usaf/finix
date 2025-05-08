# NixOS System Configuration Structure

This directory contains the NixOS system configuration files, organized in a modular structure.

## Directory Structure

- **hosts/** - Host-specific configurations
  - **default.nix** - Common configuration shared by all hosts
  - **hostname/** - Configuration specific to individual hosts
    - **default.nix** - Main host configuration
    - **hardware-configuration.nix** - Hardware-specific settings
    - **disko.nix** - Disk partitioning configuration

- **modules/** - Reusable configuration modules
  - **boot/** - Boot loader and kernel configurations
    - **default.nix** - Imports all boot modules
    - **loader.nix** - Boot loader settings
    - **kernel.nix** - Kernel settings and modules
  - **core/** - Core system functionality
  - **hardware/** - Hardware-related configurations
  - **networking/** - Network management
    - **default.nix** - Imports all networking modules
    - **manager.nix** - NetworkManager configuration
    - **xdg-portal.nix** - XDG desktop portal configuration
  - **programs/** - User applications
    - **default.nix** - Imports all program modules
    - **hyprland.nix** - Hyprland window manager configuration
  - **security/** - Security settings
  - **services/** - System services
    - **default.nix** - Imports all service modules
    - **audio.nix** - Audio (Pipewire) configuration
    - **scx.nix** - SCX scheduling service
    - **dbus.nix** - D-Bus communication service
  - **users/** - User account settings
    - **default.nix** - Imports all user modules
    - **accounts.nix** - User accounts and groups
  - **virtualization/** - Virtualization technologies
    - **default.nix** - Imports all virtualization modules
    - **containers.nix** - Container technologies (Docker, Podman)
    - **android.nix** - Android virtualization (Waydroid)

## Module Organization

Each module directory follows a consistent pattern:

1. A `default.nix` file that uses the import-modules helper to import all other .nix files in the directory
2. Specialized .nix files for specific features within that module category

This structure allows for easy addition of new modules without modifying import lists.

## Configuration Pattern

The system uses a `cfg` attribute for structured configuration options. For example:

```nix
cfg = {
  system = { 
    username = "username";
    hostname = "hostname";
    # ...
  };
  hardware = {
    bluetooth.enable = true;
    # ...
  };
  # ...
};
```

Feature flags are commonly used with `lib.mkIf` for conditional activation.