###############################################################################
# ChatGPT Module
# Provides integration for the ChatGPT desktop application
# - Configures the ChatGPT AppImage with proper environment variables
# - Sets up desktop integration
# - Handles audio and graphics dependencies
###############################################################################
{
  config,
  pkgs,
  lib,
  profile,
  inputs,
  ...
}: let
  cfg = config.modules.programs.chatgpt;
  chatgptAppImage = "/home/y0usaf/nixos/pkg/chatgpt/ChatGpt-Arch-Qt6-x86-64.AppImage";
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.programs.chatgpt = {
    enable = lib.mkEnableOption "ChatGPT desktop application";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = [
      (pkgs.writeShellScriptBin "chatgpt" ''
        # Ensure the AppImage is executable
        chmod +x ${chatgptAppImage}

        # Set up Qt-specific environment variables
        export QT_QPA_PLATFORM=xcb
        export QT_PLUGIN_PATH="${lib.makeSearchPath "lib/qt-6/plugins" [
          pkgs.qt6Packages.qtbase
          pkgs.qt6Packages.qtwayland
        ]}"

        # WebGL and graphics-related environment variables
        export QTWEBENGINE_DISABLE_SANDBOX=1
        export LIBGL_ALWAYS_SOFTWARE=1
        export WEBKIT_DISABLE_COMPOSITING_MODE=1
        export QTWEBENGINE_CHROMIUM_FLAGS="--disable-gpu --use-fake-ui-for-media-stream=0 --enable-features=WebRTCAudioDeviceEnumeration,WebRTCPipeWireCapturer"

        # Audio-related environment setup for PipeWire
        export PIPEWIRE_RUNTIME_DIR="$XDG_RUNTIME_DIR/pipewire"
        export PIPEWIRE_LATENCY="128/48000"

        # Set up config directory for persistent storage
        export XDG_CONFIG_HOME="$HOME/.config"
        export XDG_DATA_HOME="$HOME/.local/share"
        export XDG_CACHE_HOME="$HOME/.cache"

        # Debug information for storage directories
        echo "Creating and checking permissions for storage directories..."
        mkdir -p "$XDG_CONFIG_HOME/ChatGPT"
        mkdir -p "$XDG_DATA_HOME/ChatGPT"
        mkdir -p "$XDG_CACHE_HOME/ChatGPT"

        # Ensure proper permissions
        chmod 755 "$XDG_CONFIG_HOME/ChatGPT"
        chmod 755 "$XDG_DATA_HOME/ChatGPT"
        chmod 755 "$XDG_CACHE_HOME/ChatGPT"

        echo "Storage directories:"
        ls -la "$XDG_CONFIG_HOME/ChatGPT"
        ls -la "$XDG_DATA_HOME/ChatGPT"
        ls -la "$XDG_CACHE_HOME/ChatGPT"

        # Audio and microphone permissions
        export WEBKIT_FORCE_SANDBOX=0
        export QTWEBENGINE_CHROMIUM_FLAGS="--disable-gpu --use-fake-ui-for-media-stream=0 --enable-features=WebRTCAudioDeviceEnumeration"

        # Additional audio configurations
        export ALSA_PLUGIN_DIR="${pkgs.alsa-plugins}/lib/alsa-lib"
        export GST_PLUGIN_PATH="${lib.makeSearchPath "lib/gstreamer-1.0" [
          pkgs.gst_all_1.gst-plugins-base
          pkgs.gst_all_1.gst-plugins-good
        ]}"

        # Set up library path for audio/media components
        export LD_LIBRARY_PATH="${lib.makeLibraryPath [
          pkgs.qt6Packages.qtbase
          pkgs.qt6Packages.qtmultimedia
          pkgs.qt6Packages.qtwebengine
          pkgs.qt6Packages.qtwebchannel
          pkgs.qt6Packages.qtdeclarative
          pkgs.qt6Packages.qtpositioning
          pkgs.qt6Packages.qtwayland
          pkgs.libGL
          pkgs.pipewire
          pkgs.alsa-lib
          pkgs.alsa-plugins
          pkgs.gst_all_1.gst-plugins-base
          pkgs.gst_all_1.gst-plugins-good
        ]}:$LD_LIBRARY_PATH"

        # Use appimage-run to handle the AppImage execution
        export APPIMAGE_EXTRACT_AND_RUN=1
        exec ${pkgs.appimage-run}/bin/appimage-run ${chatgptAppImage} "$@"
      '')

      # Make sure appimage-run and required Qt packages are available
      pkgs.appimage-run
      pkgs.qt6Packages.qtbase
      pkgs.qt6Packages.qtmultimedia
      pkgs.qt6Packages.qtwebengine
      pkgs.qt6Packages.qtwebchannel
      pkgs.qt6Packages.qtdeclarative
      pkgs.qt6Packages.qtpositioning
      pkgs.qt6Packages.qtwayland
      pkgs.libGL
      pkgs.pipewire
      pkgs.alsa-lib
      pkgs.alsa-plugins
      pkgs.gst_all_1.gst-plugins-base
      pkgs.gst_all_1.gst-plugins-good
    ];

    ###########################################################################
    # Desktop Entries
    ###########################################################################
    xdg.desktopEntries = {
      chatgpt = {
        name = "ChatGPT";
        exec = "chatgpt %U";
        terminal = false;
        categories = ["Development" "Network" "X-AI"];
        comment = "AI Chat Client";
        icon = "chatgpt";
        mimeType = ["x-scheme-handler/chatgpt"];
      };
    };
  };
}
