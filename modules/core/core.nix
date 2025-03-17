#═══════════════════════════ 🔧 CORE SYSTEM MODULE 🔧 ═══════════════════════════#
{
  config,
  lib,
  pkgs,
  ...
}: let
  t = lib.types;
  mkOpt = type: description: lib.mkOption {inherit type description;};
  mkStr = t.str;
  mkBool = t.bool;
in {
  options.modules = {
    # System identity and core settings
    system = {
      username = mkOpt mkStr "The username for the system.";
      hostname = mkOpt mkStr "The system hostname.";
      homeDirectory = mkOpt mkStr "The path to the user's home directory.";
      stateVersion = mkOpt mkStr "The system state version.";
      timezone = mkOpt mkStr "The system timezone.";
    };

    # Core system modules
    core = {
      nvidia = {
        enable = lib.mkEnableOption "NVIDIA GPU support";
      };

      amdgpu = {
        enable = lib.mkEnableOption "AMD GPU support";
      };
    };
  };

  config = {
    # Ensure core packages are installed
    home.packages = with pkgs; [
      git
      curl
      wget
      cachix
      unzip
      bash
      vim
      lsd
      alejandra
      tree
      dconf
      lm_sensors
      bottom
      networkmanager
    ];
  };
}
