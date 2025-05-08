# NixOS Host Configuration

This directory contains the configuration for different hosts in the NixOS system.

## Multi-User Configuration

The system now supports multiple users per host. Each host can define its users in the `cfg.users` attribute.

### User Configuration Structure

```nix
cfg = {
  system = {
    hostname = "hostname";
    stateVersion = "24.11";
    timezone = "America/Toronto";
    config = "default";
  };
  
  users = {
    username1 = {
      description = "User description";
      isAdmin = true;                    # Adds user to wheel group
      homeManager = true;                # Enables home-manager for this user
      homeDirectory = "/home/username1"; # Optional, defaults to /home/username
      extraGroups = ["docker", "libvirt"]; # Additional user groups
    };
    
    username2 = {
      description = "Secondary user";
      isAdmin = false;                   # Not in wheel group
      homeManager = true;
      extraGroups = [];
    };
  };
  
  # Other configuration...
};
```

### Backward Compatibility

For backward compatibility, the system still supports the old single-user configuration with `cfg.system.username` and `cfg.system.homeDirectory`. However, this approach is deprecated and will be removed in a future version.

### Home Manager Integration

The system will automatically create Home Manager configurations for users with `homeManager = true`. Each user gets their own configuration applied to their home directory.