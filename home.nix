###############################################################################
# Home Manager Configuration
# Central configuration file for user-specific settings
# - Manages user packages and applications
# - Configures user environment and services
# - Handles module imports
###############################################################################
{
  # Parameters provided to this configuration:
  config,
  pkgs,
  lib,
  inputs,
  profile,
  ...
}: let
  ###########################################################################
  # Module Discovery
  ###########################################################################
  # Simply import the modules directory which will handle all imports via default.nix files
  allModules = [./modules];

  ###########################################################################
  # Package Management
  ###########################################################################
  # Extract default applications from profile
  defaultApps = [
    profile.modules.defaults.terminal
    profile.modules.defaults.browser
    profile.modules.defaults.fileManager
    profile.modules.defaults.launcher
    profile.modules.defaults.ide
    profile.modules.defaults.mediaPlayer
    profile.modules.defaults.imageViewer
    profile.modules.defaults.discord
    profile.modules.defaults.archiveManager
  ];

  # Extract package attribute from each app and filter out nulls
  userPackages = lib.filter (p: p != null) (map (app: app.package) defaultApps);

  # Combine all package sources
  finalPackages = userPackages ++ (profile.modules.user.packages or []);
in {
  ###########################################################################
  # Core Home Settings
  ###########################################################################
  home = {
    username = profile.modules.system.username;
    homeDirectory = profile.modules.system.homeDirectory;
    stateVersion = profile.modules.system.stateVersion;
    enableNixpkgsReleaseCheck = false;
    packages = finalPackages;
  };

  # Import all modules
  imports = allModules;

  # Pass module configurations from profile
  modules = profile.modules or {};

  ###########################################################################
  # System Configurations
  ###########################################################################
  dconf.enable = true;
}
