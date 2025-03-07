#─────────────────────── 🌍 ENVIRONMENT CONFIG ────────────────────────#
# ⚙️ System and User Environment Variables Configuration              #
#──────────────────────────────────────────────────────────────────────#
{
  config,
  pkgs,
  lib,
  profile,
  ...
}:
###############################################################################
# ENVIRONMENT CONFIGURATION MODULE
#
# This module defines:
#   • System-wide environment variables that are feature-based.
#   • User session environment variables to be used by home-manager.
#   • Conditional settings for Wayland, Hyprland, and NVIDIA.
###############################################################################
let
  ###########################################################################
  # 1. SYSTEM-WIDE ENVIRONMENT VARIABLES (FEATURE-BASED)
  ###########################################################################
  # --- Base Environment Variables ------------------------------------------
  baseEnv = {
    # Additional non-Wayland variables can be added here.
  };

  # --- NVIDIA-Specific Environment Variables ------------------------------
  nvidiaEnv = lib.mkIf (builtins.elem "nvidia" profile.features) {
    NVIDIA_DRIVER_CAPABILITIES = "all";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
    # Waydroid-specific NVIDIA settings
    WAYDROID_EXTRA_ARGS = "--gpu-mode host";
    GALLIUM_DRIVER = "nvidia";
    LIBGL_DRIVER_NAME = "nvidia";
  };

  # --- Combined System Environment Variables -----------------------------
  combinedSystemEnv = lib.mkMerge [
    baseEnv
    nvidiaEnv
  ];

  ###########################################################################
  # 2. HOME-MANAGER USER CONFIGURATION
  ###########################################################################

  # --- User Session Environment Variables ----------------------------------
  userSessionVars = {
    LIBSEAT_BACKEND = "logind";
  };
in {
  #############################################################################
  # APPLY SYSTEM-WIDE ENVIRONMENT CONFIGURATION
  #############################################################################
  environment.sessionVariables = combinedSystemEnv;

  #############################################################################
  # CONFIGURE HOME-MANAGER SETTINGS FOR USER: ${profile.username}
  #############################################################################
  home-manager.users.${profile.username} = {
    # -------------------------------------------------------------------------
    # User Home Session Variables & Executable Paths
    # -------------------------------------------------------------------------
    home = {
      sessionVariables = lib.mkMerge [
        userSessionVars
      ];

      # Define additional executable search paths for the user's session.
      sessionPath = [
        "$HOME/.local/bin"
        "/usr/lib/google-cloud-sdk/bin"
      ];
    };

    programs.zsh = {
      envExtra = lib.mkIf (builtins.elem "sync-tokens" profile.features) ''
        # Token management function
        export_vars_from_files() {
            local dir_path=$1
            for file_path in "$dir_path"/*.txt; do
                if [[ -f $file_path ]]; then
                    var_name=$(basename "$file_path" .txt)
                    export $var_name=$(cat "$file_path")
                fi
            done
        }

        # Export tokens
        export_vars_from_files "$HOME/Tokens"
      '';
    };
  };
}
