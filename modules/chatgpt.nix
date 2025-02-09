{
  config,
  pkgs,
  lib,
  profile,
  inputs,
  ...
}: let
  chatgptUnpacked = pkgs.runCommand "chatgpt-unpacked" {
    nativeBuildInputs = [ pkgs.gnutar ];
    src = pkgs.fetchurl {
      url = "https://github.com/lencx/ChatGPT/releases/download/v1.1.0/ChatGPT_1.1.0_linux_x86_64.AppImage.tar.gz";
      sha256 = "0jzhs9pkx0al1nfmmz6509l9zw12czj8s9cjgbjqcw3rkxly78gj";
    };
  } ''
    mkdir -p $out

    echo "Archive contents (using tar):"
    tar -tzf $src || true

    echo "Extracting archive using tar into \$out..."
    tar -xzf $src -C $out

    echo "Listing files in \$out after extraction:"
    find $out -type f

    cd $out

    # Locate the AppImage file at the top level
    APPIMAGE=$(find . -maxdepth 1 -type f -iname '*.appimage' | head -n1)
    if [ -z "$APPIMAGE" ]; then
      echo "Error: No AppImage file found in the extracted archive!"
      exit 1
    fi

    # Rename if needed to ensure consistency.
    if [ "$(basename "$APPIMAGE")" != "chat-gpt_1.1.0_amd64.AppImage" ]; then
      mv "$APPIMAGE" chat-gpt_1.1.0_amd64.AppImage
    fi
    chmod +x chat-gpt_1.1.0_amd64.AppImage
  '';

  chatgptWrapped = pkgs.appimageTools.wrapType2 {
    pname = "chatgpt";
    version = "1.1.0";
    src = "${chatgptUnpacked}/chat-gpt_1.1.0_amd64.AppImage";
    nativeBuildInputs = [ pkgs.squashfsTools ];
    # Remove APPDIR so that Tauri doesn't see it;
    # but leave APPIMAGE in the environment so that Tauri can verify the AppImage.
    postFixup = ''
      wrapProgram $out/bin/chatgpt --unset-env APPDIR
    '';
  };
in {
  config = {
    home.packages = [
      (pkgs.writeShellScriptBin "chatgpt" ''
        # Launch with a minimal environment. We pass along the necessary variables for GUI sessions.
        # Note: Instead of unsetting APPIMAGE, we explicitly set it to the original AppImage file.
        exec env -i \
             PATH="$PATH" \
             HOME="$HOME" \
             DISPLAY="$DISPLAY" \
             XAUTHORITY="$XAUTHORITY" \
             DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
             APPIMAGE="${chatgptUnpacked}/chat-gpt_1.1.0_amd64.AppImage" \
             ${chatgptWrapped}/bin/chatgpt "$@"
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
