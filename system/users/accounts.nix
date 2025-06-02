###############################################################################
# User Accounts Configuration
# User accounts, permissions, and shell configuration:
# - User account creation
# - Group memberships
# - Default shell settings
###############################################################################
{
  config,
  pkgs,
  hostSystem,
  ...
}: {
  config = {
    ###########################################################################
    # User Account Settings
    # User accounts, permissions, and shell configuration
    ###########################################################################
    users.users.${hostSystem.cfg.system.username} = {
      isNormalUser = true; # Defines the account as a standard user account.
      shell = pkgs.zsh; # Set Zsh as the default shell for this user.
      extraGroups = [
        "wheel" # Group that typically grants sudo permissions.
        "networkmanager" # Allows management of network connections.
        "video" # Grants permissions for video hardware usage.
        "audio" # Provides access to audio subsystems.
        "input" # Necessary for access to keyboard and mouse devices.
        "gamemode" # Include gamemode group for gaming performance tweaks.
      ];
      ignoreShellProgramCheck = true; # Skip validating that the shell is in /etc/shells.
    };
  };
}
