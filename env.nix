#─────────────────────── 🌍 ENVIRONMENT CONFIG ────────────────────────#
# ⚙️ System and User Environment Variables Configuration              #
#──────────────────────────────────────────────────────────────────────#
{
  config,
  pkgs,
  lib,
  globals,
  ...
}: {
  #── ⚙️ System-wide Environment Setup ─────────────────────────────────#
  environment.sessionVariables = {
    # 🖥️ Wayland Display Server Configuration
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";

    # 🎮 NVIDIA Graphics Configuration
    "__EGL_VENDOR_LIBRARY_FILENAMES" = "${config.hardware.nvidia.package}/share/glvnd/egl_vendor.d/10_nvidia.json";
  };

  #── 🏠 User Environment Configuration ─────────────────────────────────#
  home-manager.users.${globals.username} = {
    home = {
      #── ⚡ User Session Environment ─────────────────────────────────#
      sessionVariables = {
        #── 🌐 Browser & Display Protocol Settings ──────────────────#
        MOZ_ENABLE_WAYLAND = "1";
        LIBSEAT_BACKEND = "logind";

        #── 📦 Package Management Settings ──────────────────────────#
        NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
      };

      #── ⚡ Binary & Executable Paths ─────────────────────────────#
      sessionPath = [
        "$(npm root -g)/.bin"
        "$HOME/.local/bin"
        "/usr/lib/google-cloud-sdk/bin"
      ];
    };

    #── ⚡ Hyprland Compositor Settings ───────────────────────────────#
    wayland.windowManager.hyprland.settings = {
      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      ];
    };

    #── 🔐 Secure Token Management ──────────────────────────────────#
    home.sessionVariables.envExtra = ''
      # 🔑 Auto-load tokens from files
      if [ -d "$HOME/Tokens" ]; then
        for f in "$HOME/Tokens"/*.txt; do
          [ -f "$f" ] && export "$(basename "$f" .txt)"="$(cat "$f")"
        done
      fi
    '';
  };
}
