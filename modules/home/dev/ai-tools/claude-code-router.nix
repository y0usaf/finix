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
    users.users.${config.user.name}.maid = {
      packages = with pkgs; [
        nodejs_20
      ];

      file.home = {
        ".claude-code-router/.keep".text = "";
      };

      systemd.tmpfiles.dynamicRules = [
        "d {{home}}/.npm-global 0755 {{user}} {{group}} - -"
        "d {{home}}/.claude-code-router 0755 {{user}} {{group}} - -"
      ];
    };

    # Add npm global bin to PATH
    environment.variables.PATH = lib.mkAfter "${config.user.homeDirectory}/.npm-global/bin";

    systemd.services.claude-code-router-install = {
      description = "Install Claude Code Router via npm";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        User = config.user.name;
        ExecStart = ''/bin/sh -c "export NPM_CONFIG_PREFIX=${config.user.homeDirectory}/.npm-global && if ! command -v ccr >/dev/null 2>&1; then mkdir -p $NPM_CONFIG_PREFIX && npm install -g @musistudio/claude-code-router; fi"'';
        RemainAfterExit = true;
      };
      path = with pkgs; [nodejs_20 bash];
    };
  };
}
