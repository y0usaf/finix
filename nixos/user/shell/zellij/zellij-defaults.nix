{lib, ...}: {
  imports = [
    ./zellij-options.nix
  ];

  config = {
    user.shell.zellij.zjstatus.layout = lib.mkDefault ''
      layout {
        default_tab_template {
          pane size=1 borderless=true {
            ${(import ./data/zellij-lib.nix {inherit lib;}).zjstatus.zjstatusTopBar}
          }
          children
          pane size=1 borderless=true {
            ${(import ./data/zellij-lib.nix {inherit lib;}).zjstatus.zjstatusHintsBar}
          }
        }
      }
    '';
  };
}
