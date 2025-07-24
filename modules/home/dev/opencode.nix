{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.opencode;
in {
  options.home.dev.opencode = {
    enable = lib.mkEnableOption "OpenCode development tools";
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid.packages = with pkgs; [
      nodejs
    ];
    
    system.activationScripts.opencode = {
      text = ''
        if ! sudo -u y0usaf command -v opencode &> /dev/null; then
          echo "Installing opencode via npm for user y0usaf..."
          sudo -u y0usaf npm install -g @sst/opencode
        fi
      '';
      deps = [];
    };
  };
}
