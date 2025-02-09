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
        
        # Use appimage-run to handle the AppImage execution
        exec ${pkgs.appimage-run}/bin/appimage-run ${chatgptAppImage} "$@"
      '')
      
      # Make sure appimage-run is available
      pkgs.appimage-run
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
