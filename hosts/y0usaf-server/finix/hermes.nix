# Hermes Agent (NousResearch) as a finix-native service.
#
# Upstream ships only a NixOS module (systemd + optional OCI container). The
# server runs finix (finit pid1) and deliberately dropped docker/podman, so we
# replicate the native-service surface here: stateDir /var/lib/hermes bound
# from /persist, HERMES_HOME=$stateDir/.hermes, declarative config.yaml, and
# secret injection via $HERMES_HOME/.env (hermes reads it on startup).
#
# Interactive surface (upstream services.hermes-agent.addToSystemPackages
# parity): CLI on PATH via environment.systemPackages, HERMES_HOME exported so
# shells share the gateway's state, y0usaf joins the hermes group, and state
# dirs/files are group-writable/readable (2770/0660/0640) so `hermes config
# set` and one-shot runs don't hit EACCES.
#
# Provider: "ai-gateway" = Vercel AI Gateway (key AI_GATEWAY_API_KEY).
#
# NOTE (verified 2026-08-01 against hermes-agent 0.19.0, rev 2b0fb72): the
# "minimal" package ships NO baked-in "ai-gateway" provider profile (the
# orchestrator's assumption that the base URL is pre-registered does not hold
# for this revision). We therefore register it as a USER model-provider plugin
# under $HERMES_HOME/plugins/model-providers/ai-gateway/ — a documented native
# hermes mechanism (providers/__init__.py: "User plugins override bundled
# plugins on name collision... third parties can monkey-patch or replace any
# built-in profile"). The profile points base_url at
# https://ai-gateway.vercel.sh/v1 and reads the key from AI_GATEWAY_API_KEY.
# Also verified: model.default must be the BARE gateway slug
# ("anthropic/claude-sonnet-4") with provider set separately — a
# "ai-gateway/anthropic/claude-sonnet-4" model.default makes the gateway
# receive the whole string as model id and answer HTTP 404.
{ lib, pkgs, flakeInputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  hermes = flakeInputs.hermes-agent.packages.${system}.minimal;
  stateDir = "/var/lib/hermes";
  homeDir = "${stateDir}/.hermes";

  configYaml = (pkgs.formats.yaml { }).generate "hermes-config.yaml" {
    model = {
      default = "anthropic/claude-sonnet-4";
      provider = "ai-gateway";
    };
  };

  aiGatewayProviderPy = pkgs.writeText "ai-gateway-provider.py" ''
    """Vercel AI Gateway provider profile (user plugin).

    Routes to the Vercel AI Gateway OpenAI-compatible endpoint. The gateway
    accepts a provider-prefixed model slug (e.g. anthropic/claude-sonnet-4)
    and forwards to the underlying model provider. API key read from
    AI_GATEWAY_API_KEY in ~/.hermes/.env.
    """
    from providers import register_provider
    from providers.base import ProviderProfile


    ai_gateway = ProviderProfile(
        name="ai-gateway",
        aliases=("gateway", "vercel", "vercel-ai-gateway"),
        display_name="Vercel AI Gateway",
        description="Vercel AI Gateway — OpenAI-compatible proxy to many models",
        env_vars=("AI_GATEWAY_API_KEY",),
        base_url="https://ai-gateway.vercel.sh/v1",
        auth_type="api_key",
        api_mode="chat_completions",
    )

    register_provider(ai_gateway)
  '';
in {
  environment = {
    systemPackages = [ hermes ];
    variables.HERMES_HOME = homeDir;
  };

  fileSystems."${stateDir}" = {
    device = "/persist${stateDir}";
    fsType = "btrfs";
    options = [ "bind" ];
    neededForBoot = true;
  };

  users = {
    users.hermes = {
      isSystemUser = true;
      group = "hermes";
      home = stateDir;
    };
    users.y0usaf.extraGroups = [ "hermes" ];
    groups.hermes = { };
  };

  # Root-side seed: dirs, first-boot config.yaml, the ai-gateway provider
  # plugin, and AI_GATEWAY_API_KEY into .env from
  # /persist/secrets/hermes/ai-gateway-api-key. Idempotent.
  finit.tasks."hermes-dirs" = {
    description = "prepare hermes state dirs and seed config/env";
    command = pkgs.writeShellScript "hermes-dirs" ''
      set -eu
      export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gnugrep ]}
      mkdir -p ${homeDir}/cron ${homeDir}/sessions ${homeDir}/logs ${homeDir}/memories ${homeDir}/plugins/
      mkdir -p ${homeDir}/plugins/model-providers/ai-gateway
      # 2770 = setgid + group-writable: y0usaf (hermes group) shares state
      # with the gateway service (parity with upstream tmpfiles rules).
      chmod 2770 ${stateDir} ${homeDir}
      chmod 2770 ${homeDir}/cron ${homeDir}/sessions ${homeDir}/logs ${homeDir}/memories
      chmod 2770 ${homeDir}/plugins ${homeDir}/plugins/model-providers/ai-gateway
      chown -R hermes:hermes ${stateDir} 2>/dev/null || true
      if [ ! -f ${homeDir}/config.yaml ]; then
        install -o hermes -g hermes -m 0660 ${configYaml} ${homeDir}/config.yaml
      else
        chmod 0660 ${homeDir}/config.yaml 2>/dev/null || true
      fi
      # Declarative ai-gateway provider profile (hermes user plugin).
      install -o hermes -g hermes -m 0644 ${aiGatewayProviderPy} \
        ${homeDir}/plugins/model-providers/ai-gateway/__init__.py
      secret=/persist/secrets/hermes/ai-gateway-api-key
      if [ -r "$secret" ] && { [ ! -f ${homeDir}/.env ] || ! grep -q '^AI_GATEWAY_API_KEY=' ${homeDir}/.env 2>/dev/null; }; then
        key="$(tr -d '\r\n' < "$secret")"
        tmp=${homeDir}/.env.tmp
        { echo "AI_GATEWAY_API_KEY=$key"; grep -v '^AI_GATEWAY_API_KEY=' ${homeDir}/.env 2>/dev/null || true; } > "$tmp"
        mv "$tmp" ${homeDir}/.env
        chown hermes:hermes ${homeDir}/.env
        # 0640: hermes-group members (y0usaf) read it; the gateway itself
        # runs as hermes (owner). Parity with upstream's 0640 .env.
        chmod 0640 ${homeDir}/.env
      fi
    '';
    log = true;
  };

  finit.services."hermes-gateway" = {
    description = "hermes agent gateway (Vercel AI Gateway provider)";
    user = "hermes";
    group = "hermes";
    command = "${pkgs.writeShellScript "hermes-gateway-start" ''
      set -eu
      export PATH=${lib.makeBinPath [ pkgs.coreutils ]}
      exec ${hermes}/bin/hermes gateway run
    ''}";
    environment = {
      HOME = stateDir;
      HERMES_HOME = homeDir;
      HERMES_MANAGED = "true";
    };
    conditions = [ "net/lo/up" "task/hermes-dirs/success" ];
    log = true;
  };
}
