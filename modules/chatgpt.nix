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
        # Ensure the AppImage is executable.
        chmod +x ${chatgptAppImage}
        # Launch the AppImage using glibc's dynamic linker to avoid the NixOS stub-ld error.
        exec env -i \
             PATH="$PATH" \
             HOME="$HOME" \
             DISPLAY="$DISPLAY" \
             XAUTHORITY="$XAUTHORITY" \
             DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
             ${pkgs.glibc.out}/lib/ld-linux-x86-64.so.2 \
             --library-path ${pkgs.glibc.out}/lib \
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
