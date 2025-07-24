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
    
    systemd.services.opencode-install = {
      description = "Install OpenCode via npm";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "y0usaf";
        ExecStart = ''/bin/sh -c "if ! command -v opencode >/dev/null 2>&1; then npm install -g @sst/opencode; fi"'';
        RemainAfterExit = true;
      };
      path = with pkgs; [ nodejs bash ];
    };
  };
}
