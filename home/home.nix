###############################################################################
# Home Manager Configuration
# Central entry point for user-specific settings
# - Imports all home modules
###############################################################################
{lib, ...}: {
  # Import all modules from the ./modules directory
  imports = [./modules];
}
