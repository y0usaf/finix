{
  config,
  pkgs,
  lib,
  profile,
  inputs,
  ...
}: let
  chatgptAppImage = "/home/y0usaf/nixos/pkg/chatgpt/ChatGpt-Arch-Qt6-x86-64.AppImage";
in {
  config = {
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
        export QTWEBENGINE_CHROMIUM_FLAGS="--disable-gpu"
        
        # Audio-related environment setup
        export PULSE_SERVER="unix:$XDG_RUNTIME_DIR/pulse/native"
        export PULSE_COOKIE="$XDG_RUNTIME_DIR/pulse/cookie"
        
        # Set up config directory for persistent storage
        export XDG_CONFIG_HOME="$HOME/.config"
        export XDG_DATA_HOME="$HOME/.local/share"
        export XDG_CACHE_HOME="$HOME/.cache"
        
        # Create necessary directories if they don't exist
        mkdir -p "$XDG_CONFIG_HOME/ChatGPT"
        mkdir -p "$XDG_DATA_HOME/ChatGPT"
        mkdir -p "$XDG_CACHE_HOME/ChatGPT"
        
        # Set up library path for Qt6 multimedia
        export LD_LIBRARY_PATH="${lib.makeLibraryPath [
          pkgs.qt6Packages.qtbase
          pkgs.qt6Packages.qtmultimedia
          pkgs.qt6Packages.qtwebengine
          pkgs.qt6Packages.qtwebchannel
          pkgs.qt6Packages.qtdeclarative
          pkgs.qt6Packages.qtpositioning
          pkgs.qt6Packages.qtwayland
          pkgs.libGL
          pkgs.pulseaudio
        ]}:$LD_LIBRARY_PATH"
        
        # Use appimage-run to handle the AppImage execution
        exec ${pkgs.appimage-run}/bin/appimage-run \
          ${chatgptAppImage} "$@"
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
      pkgs.pulseaudio
    ];

    xdg.desktopEntries = {
      chatgpt = {
        name = "ChatGPT";
        exec = "chatgpt %U";
        terminal = false;
        categories = ["Development" "Network" "X-AI"];
        comment = "AI Chat Client";
        icon = "chatgpt";
      };
    };
  };
}
