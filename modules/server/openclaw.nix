{
  config,
  lib,
  pkgs,
  ...
}: let
  home = config.user.homeDirectory;
  state = "${home}/.openclaw";
  model = "vercel-ai-gateway/deepseek/deepseek-v4.1-flash-1017";

  configFile = pkgs.writeText "openclaw.json" (builtins.toJSON {
    gateway = {
      mode = "local";
      port = 18789;
      bind = "tailnet";
      auth = {
        mode = "token";
        allowTailscale = true;
      };
    };
    agents.entries.main = {
      inherit (config.user) name;
      workspace = "${home}/.openclaw/workspace";
      model.primary = model;
    };
  });
in {
  environment.systemPackages = [pkgs.openclaw];

  finix.persistence.allowlist.users.${config.user.name}.directories = [".openclaw"];

  finit.services.openclaw = {
    description = "OpenClaw gateway: the phone-facing personal assistant";
    user = config.user.name;
    group = "users";
    command = "${pkgs.writeShellScript "openclaw-gateway" ''
      set -eu
      install -d -m 0700 ${state} ${state}/tmp
      install -m 0600 ${configFile} ${state}/openclaw.json
      if [ ! -s ${state}/gateway-token ]; then
        head -c 32 /dev/urandom | base64 | tr -d '=+/\n' > ${state}/gateway-token
        chmod 0400 ${state}/gateway-token
      fi
      if [ -r ${home}/Tokens/AI_GATEWAY_API_KEY.txt ]; then
        AI_GATEWAY_API_KEY="$(cat ${home}/Tokens/AI_GATEWAY_API_KEY.txt)"
        export AI_GATEWAY_API_KEY
      fi
      OPENCLAW_GATEWAY_TOKEN="$(cat ${state}/gateway-token)"
      export OPENCLAW_GATEWAY_TOKEN
      exec ${pkgs.openclaw}/bin/openclaw gateway
    ''}";
    environment = {
      HOME = home;
      OPENCLAW_HOME = home;
      OPENCLAW_STATE_DIR = state;
      TMPDIR = "${state}/tmp";
    };
    path = [pkgs.coreutils];
    conditions = ["net/lo/up" "net/tailscale0/up"];
    log = true;
  };
}
