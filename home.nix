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
  # Find all module files recursively
  findModules = dir: let
    contents = builtins.readDir dir;

    handleEntry = name: type: let
      path = "${dir}/${name}";
    in
      if type == "regular" && lib.hasSuffix ".nix" name
      then [path]
      else if type == "directory"
      then findModules path
      else [];
  in
    lib.flatten (lib.mapAttrsToList handleEntry contents);

  # Get all module files and filter out problematic ones
  allFiles = findModules ./modules;

  # Explicitly filter out problematic files
  moduleFiles =
    builtins.filter (
      path:
        !(lib.hasSuffix "template.nix" path)
        && !(lib.hasSuffix "env.nix" path)
        && !(lib.hasSuffix "profiles.nix" path)
        && !(lib.hasSuffix "android.nix" path)
    )
    allFiles;

  # Import all modules
  allModules = moduleFiles;

  ###########################################################################
  # Package Management
  ###########################################################################
  # Extract default applications from profile
  defaultApps = [
    profile.defaultTerminal
    profile.defaultBrowser
    profile.defaultFileManager
    profile.defaultLauncher
    profile.defaultIde
    profile.defaultMediaPlayer
    profile.defaultImageViewer
    profile.defaultDiscord
  ];

  # Extract package attribute from each app and filter out nulls
  userPackages = lib.filter (p: p != null) (map (app: app.package) defaultApps);

  # Combine all package sources
  finalPackages = userPackages ++ profile.personalPackages;
in {
  ###########################################################################
  # Core Home Settings
  ###########################################################################
  home = {
    username = profile.username;
    homeDirectory = profile.homeDirectory;
    stateVersion = profile.stateVersion;
    enableNixpkgsReleaseCheck = false;
    packages = finalPackages;
  };

  # Import all modules
  imports = allModules;

  # Pass module configurations from profile
  modules = profile.modules or {};

  ###########################################################################
  # Program Configurations
  ###########################################################################
  programs.nh = {
    enable = true;
    flake = profile.flakeDir;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 7d";
    };
  };

  ###########################################################################
  # System Configurations
  ###########################################################################
  dconf.enable = true;
}
