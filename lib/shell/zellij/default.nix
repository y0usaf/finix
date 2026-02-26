{lib, ...}: {
  imports = [
    ./options.nix
  ];

  config = {
    user.shell.zellij.zjstatus.layout = lib.mkDefault ''
      layout {
        default_tab_template {
          pane size=1 borderless=true {
            ${(import ./config.nix {inherit lib;}).zjstatus.zjstatusTopBar}
          }
          children
          pane size=1 borderless=true {
            ${(import ./config.nix {inherit lib;}).zjstatus.zjstatusHintsBar}
          }
        }
      }
    '';
  };
}
