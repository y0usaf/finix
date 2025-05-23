#═══════════════════════════ 🔧 SYSTEM CONFIGURATION MODULE 🔧 ═══════════════════════════#
{
  config,
  lib,
  pkgs,
  inputs,
  hostSystem,
  hostHome,
  ...
}: let
  helpers = import ../../../lib/helpers/module-defs.nix {inherit lib;};
  inherit (helpers) mkOptDef mkStr;
in {
  options.cfg.system = {
    username = mkOptDef mkStr hostSystem.cfg.system.username "The username for the system.";
    hostname = mkOptDef mkStr hostSystem.cfg.system.hostname "The system hostname.";
    homeDirectory = mkOptDef mkStr hostSystem.cfg.system.homeDirectory "The path to the user's home directory.";
    stateVersion = mkOptDef mkStr hostSystem.cfg.system.stateVersion "The system state version.";
    timezone = mkOptDef mkStr hostSystem.cfg.system.timezone "The system timezone.";
    config = mkOptDef mkStr hostSystem.cfg.system.config "The system configuration type.";
  };

  # Core GPU modules
  options.cfg.core = {
    nvidia = {
      enable = lib.mkEnableOption "NVIDIA GPU support";
    };
    amdgpu = {
      enable = lib.mkEnableOption "AMD GPU support";
    };
  };

  config.home = {
    username = config.cfg.system.username;
    homeDirectory = config.cfg.system.homeDirectory;
    stateVersion = config.cfg.system.stateVersion;
    enableNixpkgsReleaseCheck = false;
  };
}