{lib, ...}: let
  cfg = import ./config.nix {inherit lib;};
in {
  imports = [
    ./options.nix
  ];

  config = {
    user.shell.zellij.zjstatus.layout = lib.mkDefault ''
      layout {
        default_tab_template {
          pane size=1 borderless=true {
            ${cfg.zjstatus.zjstatusTopBar}
          }
          children
          pane size=1 borderless=true {
            ${cfg.zjstatus.zjstatusHintsBar}
          }
        }
      }
    '';
  };
}
