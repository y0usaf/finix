{
  config,
  pkgs,
  lib,
  profile,
  inputs,
  ...
}: let
  chatgpt-wrapped = pkgs.appimageTools.wrapType2 {
    pname = "chatgpt";
    version = "1.1.0";
    src = pkgs.fetchurl {
      url = "https://github.com/lencx/ChatGPT/releases/download/v1.1.0/ChatGPT_1.1.0_linux_x86_64.AppImage.tar.gz";
      sha256 = "0jzhs9pkx0al1nfmmz6509l9zw12czj8s9cjgbjqcw3rkxly78gj";
    };
  };
in {
  config = {
    home.packages = [
      (pkgs.writeShellScriptBin "chatgpt" ''
        exec ${chatgpt-wrapped}/bin/chatgpt "$@"
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
