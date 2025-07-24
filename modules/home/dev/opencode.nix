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
        ExecStart = ''/bin/sh -c "export NPM_CONFIG_PREFIX=/home/y0usaf/.npm-global && if ! command -v opencode >/dev/null 2>&1; then mkdir -p $NPM_CONFIG_PREFIX && npm install -g opencode-ai; fi"'';
        RemainAfterExit = true;
      };
      path = with pkgs; [ nodejs bash ];
    };
  };
}
