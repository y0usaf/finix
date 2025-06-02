###############################################################################
# Sudo Configuration Module
# System administrator privileges:
# - User-specific sudo rules
# - Password-less sudo for specific users
# - Fine-grained command permissions
###############################################################################
{hostSystem, ...}: {
  config = {
    ###########################################################################
    # Sudo Configuration
    # Configure sudo permissions for users
    ###########################################################################
    security.sudo.extraRules = [
      {
        users = [hostSystem.cfg.system.username]; # The user defined in the hostSystem
        commands = [
          {
            command = "ALL"; # Allow all commands
            options = ["NOPASSWD"]; # No password prompt for these commands
          }
        ];
      }
    ];
  };
}
