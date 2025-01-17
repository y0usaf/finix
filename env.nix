#─────────────────────── 🌍 ENVIRONMENT CONFIG ────────────────────────#
# ⚠️  Root access required | System rebuild needed for changes        #
#──────────────────────────────────────────────────────────────────────#
{
  config,
  pkgs,
  lib,
  globals,
  ...
}: {
  #── 🔧 System Variables ──────────────────#
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";

    #── 📱 Waydroid Settings ──────────────#
    WAYDROID_EXTRA_ARGS = "--wayland --nvidia";
    WAYDROID_LOG_LEVEL = "debug";
  };

  #── 🏠 Home Manager Config ──────────────#
  home-manager.users.${globals.username} = {
    home = {
      #── 🌐 Session Variables ────────────#
      sessionVariables = {
        #── 🪟 Wayland Settings ──────────#
        MOZ_ENABLE_WAYLAND = "1";
        LIBSEAT_BACKEND = "logind";

        #── ⚡ Runtime Settings ──────────#
        NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
      };

      #── 📁 Path Configuration ──────────#
      sessionPath = [
        "$(npm root -g)/.bin"
        "$HOME/.local/bin"
        "/usr/lib/google-cloud-sdk/bin"
      ];
    };

    #── 🪟 Hyprland Settings ─────────────#
    wayland.windowManager.hyprland.settings = {
      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,hicolor"
      ];
    };

    #── 🔑 Token Management ──────────────#
    home.sessionVariables.envExtra = ''
      # Export tokens
      if [ -d "$HOME/Tokens" ]; then
        for f in "$HOME/Tokens"/*.txt; do
          [ -f "$f" ] && export "$(basename "$f" .txt)"="$(cat "$f")"
        done
      fi
    '';
  };
}
