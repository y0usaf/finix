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

  # --- Wayland-Specific Environment Variables ------------------------------
  waylandEnv = lib.mkIf (builtins.elem "wayland" profile.features) {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    XDG_SESSION_TYPE = "wayland";
    GDK_BACKEND = "wayland,x11";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
  };

  # --- Hyprland-Specific Environment Variables -----------------------------
  hyprlandEnv = lib.mkIf (builtins.elem "hyprland" profile.features) {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
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
    waylandEnv
    hyprlandEnv
    nvidiaEnv
  ];

  ###########################################################################
  # 2. HOME-MANAGER USER CONFIGURATION
  ###########################################################################

  # --- User Session Environment Variables ----------------------------------
  userSessionVars = {
    MOZ_ENABLE_WAYLAND = "1";
    LIBSEAT_BACKEND = "logind";
    NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
  };

  # --- Token Loader Script -------------------------------------------------
  tokenLoaderScript = ''
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

  # --- Hyprland NVIDIA-Specific Environment Settings -----------------------
  hyprlandNvidiaEnv = lib.mkIf (builtins.elem "nvidia" profile.features) [
    "LIBVA_DRIVER_NAME,nvidia"
    "GBM_BACKEND,nvidia-drm"
    "__GLX_VENDOR_LIBRARY_NAME,nvidia"
  ];
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
        {
          envExtra = tokenLoaderScript;
        }
      ];

      # Define additional executable search paths for the user's session.
      sessionPath = [
        "$(npm root -g)/.bin"
        "$HOME/.local/bin"
        "/usr/lib/google-cloud-sdk/bin"
      ];
    };

    # -------------------------------------------------------------------------
    # Hyprland Window Manager Settings (with Conditional NVIDIA Options)
    # -------------------------------------------------------------------------
    wayland.windowManager.hyprland.settings = {
      env = hyprlandNvidiaEnv;
    };
  };
}
