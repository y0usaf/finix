#═══════════════════════════ 🔧 CORE SYSTEM MODULE 🔧 ═══════════════════════════#
# This module serves as the main import point for core system functionality
# It's been split into smaller, more focused modules for maintainability
{
  config,
  lib,
  pkgs,
  inputs,
  hostSystem,
  hostHome,
  ...
}: {
  # Import all sub-modules to build the complete core functionality
  imports = [
    ./system.nix     # System identity and core settings
    ./packages.nix   # Package management and default apps
    ./environment.nix # Environment variables and session settings
    ./user.nix       # User-specific configurations
    ./directories.nix # Directory structure configuration
  ];
}