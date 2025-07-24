{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.claude-code-router;
in {
  options.home.dev.claude-code-router = {
    enable = lib.mkEnableOption "Claude Code Router";
  };

  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid = {
      packages = with pkgs; [
        nodejs_20
      ];

      file.home = {
        ".claude-code-router/.keep".text = "";
      };
    };

    # Add npm global bin to PATH
    environment.variables.PATH = lib.mkAfter "/home/y0usaf/.npm-global/bin";

    # Ensure directories exist
    users.users.y0usaf.maid.systemd.tmpfiles.dynamicRules = [
      "d {{home}}/.npm-global 0755 {{user}} {{group}} - -"
      "d {{home}}/.claude-code-router 0755 {{user}} {{group}} - -"
    ];

    systemd.services.claude-code-router-install = {
      description = "Install Claude Code Router via npm";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        User = "y0usaf";
        ExecStart = ''/bin/sh -c "export NPM_CONFIG_PREFIX=/home/y0usaf/.npm-global && if ! command -v ccr >/dev/null 2>&1; then mkdir -p $NPM_CONFIG_PREFIX && npm install -g @musistudio/claude-code-router; fi"'';
        RemainAfterExit = true;
      };
      path = with pkgs; [nodejs_20 bash];
    };
  };
}
