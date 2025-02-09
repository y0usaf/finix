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
        
        # Set up library path for Qt6 multimedia
        export LD_LIBRARY_PATH="${lib.makeLibraryPath [
          pkgs.qt6Packages.qtbase
          pkgs.qt6Packages.qtmultimedia
          pkgs.qt6Packages.qtwebengine
          pkgs.qt6Packages.qtwebchannel
          pkgs.qt6Packages.qtdeclarative
          pkgs.qt6Packages.qtpositioning
        ]}:$LD_LIBRARY_PATH"
        
        # Use appimage-run to handle the AppImage execution
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
