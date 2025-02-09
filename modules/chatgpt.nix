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
        
        # Set up Qt-specific environment variables and library paths
        export QT_PLUGIN_PATH="${pkgs.qt6Packages.qtbase}/lib/qt-6/plugins"
        export QT_QPA_PLATFORM_PLUGIN_PATH="${pkgs.qt6Packages.qtbase}/lib/qt-6/plugins/platforms"
        export LD_LIBRARY_PATH="${pkgs.qt6Packages.qtbase}/lib:${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
        
        # Launch the AppImage with the necessary environment
        exec env -i \
             PATH="$PATH" \
             HOME="$HOME" \
             DISPLAY="$DISPLAY" \
             XAUTHORITY="$XAUTHORITY" \
             DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
             QT_PLUGIN_PATH="$QT_PLUGIN_PATH" \
             QT_QPA_PLATFORM_PLUGIN_PATH="$QT_QPA_PLATFORM_PLUGIN_PATH" \
             LD_LIBRARY_PATH="$LD_LIBRARY_PATH" \
             ${pkgs.glibc.out}/lib/ld-linux-x86-64.so.2 \
             --library-path ${lib.makeLibraryPath [
               pkgs.qt6Packages.qtbase
               pkgs.stdenv.cc.cc.lib
               pkgs.glibc
             ]} \
             ${chatgptAppImage} "$@"
      '')
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
