###############################################################################
# Security Configuration Module
# System security measures and access control:
# - Real-time kit for audio/video tasks
# - PolicyKit for fine-grained permission control
# - Sudo configurations
###############################################################################
{
  config,
  lib,
  pkgs,
  profile,
  ...
}: {
  config = {
    ###########################################################################
    # Security & Permissions
    # System security measures and access control
    ###########################################################################
    security = {
      rtkit.enable = true; # Enable real-time priority management (often needed for audio/video tasks).
      polkit.enable = true; # Enable PolicyKit for fine-grained permission control.
      # Configure sudo so that the primary user can run all commands without a password.
      sudo.extraRules = [
        {
          users = [profile.cfg.system.username]; # The user defined in the profile.
          commands = [
            {
              command = "ALL"; # Allow all commands.
              options = ["NOPASSWD"]; # No password prompt for these commands.
            }
          ];
        }
      ];
    };
  };
}
