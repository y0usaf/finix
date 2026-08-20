# DeepSeek Harness web server as an always-on finit service, exposed on the
# tailnet.
#
# The dsh package + web app come from the local deepseek-harness flake
# (inputs.deepseek-harness). We run the SAME invocation the GUI was launched
# with manually (headless + web profiles) so the always-on server is a drop-in
# replacement for the ad-hoc `dsh --profile headless --profile web` process.
#
# Tailnet exposure:
#   - primary:  https://y0usaf-desktop.tail865e88.ts.net
#   - fallback: http://y0usaf-desktop:3080
# tailscaled fronts both listeners while DSH stays on loopback. Tailnet traffic
# remains WireGuard-encrypted, but browsers classify the HTTP origin as
# insecure; the packaged frontend supplies the missing crypto.randomUUID API.
# HTTPS remains primary because other future secure-context APIs are not shimmed.
# The /api browser-trust fence accepts the full and short MagicDNS names
# forwarded by tailscale serve.
#
# Serve must be enabled once per tailnet in the admin console (the finit task
# below retries until it is):
#   https://login.tailscale.com/f/serve?node=<node>
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  dsh = flakeInputs.deepseek-harness.packages."${system}".dsh;
  pluginSource = flakeInputs.deepseek-harness.outPath;
  pluginNames = [
    "dsh-unround-ui"
    "dsh-neon-theme"
    "dsh-spring-motion"
    "dsh-dopamine-fx"
    "dsh-sidebar-gradient"
    "dsh-no-collapse-button"
    "dsh-ablate"
    "dsh-composer-glow"
    "dsh-thinking-rainbow"
    "dsh-tool-burst-compress"
    "dsh-archive-session"
    "dsh-plugin-toggle"
    "dsh-chronobreak"
    "dsh-finishline"
    "dsh-full-access"
    "dsh-rush"
  ];
  managedPatch = pkgs.writeText "dsh-web-managed.patch.yml" ''
    # >>> finix-managed-dsh-plugins
    - insert:
        - id: unround-ui
          name: dsh-unround-ui
        - id: neon-theme
          name: dsh-neon-theme
        - id: spring-motion
          name: dsh-spring-motion
        - id: dopamine-fx
          name: dsh-dopamine-fx
        - id: sidebar-gradient
          name: dsh-sidebar-gradient
        - id: no-collapse-button
          name: dsh-no-collapse-button
        - id: ablate
          name: dsh-ablate
        - id: composer-glow
          name: dsh-composer-glow
        - id: thinking-rainbow
          name: dsh-thinking-rainbow
        - id: tool-burst-compress
          name: dsh-tool-burst-compress
        - id: archive-session
          name: dsh-archive-session
        - id: plugin-toggle
          name: dsh-plugin-toggle
        - id: chronobreak
          name: dsh-chronobreak
        - id: finishline
          name: dsh-finishline
        # Deliberate: disables file sandbox restrictions and approval prompts.
        - id: full-access
          name: dsh-full-access
        # Swap the shell executor from bash to rush.
        - id: rush
          name: dsh-rush

    # dsh-rush registers as ctx.shell in place of the bash executor.
    - id: bash-sandbox
      disabled: true

    # Proper Vercel route; secret remains an environment reference.
    - id: llm-pi-ai
      config:
        providers:
          vercel-ai-gateway:
            displayName: Vercel AI Gateway
            apiKeyEnv: AI_GATEWAY_API_KEY

            models:
              - id: deepseek/deepseek-v4-pro-0813
                name: DeepSeek V4 Pro 0813
                contextWindow: 1000000
                maxTokens: 384000
                input: [text]
                reasoningEfforts:
                  off:
                  low: low
                  medium: medium
                  high: high
              - id: deepseek/deepseek-v4-flash-0731
                name: DeepSeek V4 Flash 0731
                contextWindow: 1000000
                maxTokens: 384000
                input: [text]
                reasoningEfforts:
                  off:
                  low: low
                  medium: medium
                  high: high
              - id: moonshotai/kimi-k3
                name: Kimi K3
                contextWindow: 1000000
                maxTokens: 131072
                input: [text, image]
                reasoningEfforts:
                  off:
                  low: low
                  medium: medium
                  high: high
              - id: moonshotai/kimi-k3-fast
                name: Kimi K3 Fast
                contextWindow: 1000000
                maxTokens: 131072
                input: [text, image]
                reasoningEfforts:
                  off:
                  low: low
                  medium: medium
                  high: high
    - id: agent-default-model
      config:
        provider: vercel-ai-gateway
        model: deepseek/deepseek-v4-pro-0813
    # <<< finix-managed-dsh-plugins
  '';
  user = config.user.name;
  home = config.user.homeDirectory;
  tailnetHost = "y0usaf-desktop.tail865e88.ts.net";
  tailnetShort = "y0usaf-desktop";

  port = 3080;

  # Re-link every custom plugin to the current immutable input and reconcile
  # only the managed patch block. User overrides (including plugin-toggle's
  # managed-disable block) remain intact across service restarts.
  webCommand = pkgs.writeShellScript "dsh-web-start" ''
    set -eu
    export PATH=${lib.makeBinPath [
      pkgs.nodejs_22
      pkgs.coreutils
      pkgs.bash
      pkgs.rush
      pkgs.git
    ]}:''$PATH

    profile_dir="''${DSH_HOME:-${home}/.dsh}/profiles/web"
    mkdir -p "$profile_dir/node_modules"
    for plugin in ${lib.escapeShellArgs pluginNames}; do
      ln -sfn "${pluginSource}/$plugin" "$profile_dir/node_modules/$plugin"
    done

    "${pkgs.nodejs_22}/bin/node" - "$profile_dir/cordis.patch.yml" "${managedPatch}" <<'NODE'
    const fs = require("node:fs");
    const [target, managedPath] = process.argv.slice(2);
    const start = "# >>> finix-managed-dsh-plugins";
    const end = "# <<< finix-managed-dsh-plugins";
    const header = "# Your patch layer for this dsh profile, applied after every bundle layer.\n"
      + "# Custom packages/provider defaults are managed by hosts/y0usaf-desktop/finix/dsh-web.nix.\n\n";
    const managed = fs.readFileSync(managedPath, "utf8").trimEnd();
    let current = "";
    try { current = fs.readFileSync(target, "utf8"); } catch {}
    const meaningful = current.split("\n")
      .map((line) => line.trim())
      .filter((line) => line !== "" && !line.startsWith("#"));
    let next;
    if (meaningful.length === 0 || (meaningful.length === 1 && meaningful[0] === "[]")) {
      next = header + managed + "\n";
    } else {
      const startAt = current.indexOf(start);
      const endAt = current.indexOf(end, startAt + start.length);
      if (startAt >= 0 && endAt >= 0) {
        next = current.slice(0, startAt) + managed + current.slice(endAt + end.length);
      } else {
        next = current.trimEnd() + "\n\n" + managed + "\n";
      }
    }
    if (!next.endsWith("\n")) next += "\n";
    if (next !== current) {
      const temporary = target + "." + process.pid + ".tmp";
      fs.writeFileSync(temporary, next, { mode: 0o644 });
      fs.renameSync(temporary, target);
    }
    NODE

    if [ -z "''${AI_GATEWAY_API_KEY:-}" ] && [ -f "${home}/Tokens/AI_GATEWAY_API_KEY.txt" ]; then
      AI_GATEWAY_API_KEY="''$(tr -d '\r\n' < "${home}/Tokens/AI_GATEWAY_API_KEY.txt")"
      export AI_GATEWAY_API_KEY
    fi
    exec "${dsh}/bin/dsh" --profile headless --profile web \
      --host 127.0.0.1 --port ${toString port} \
      --trusted-host ${tailnetHost} \
      --trusted-host ${tailnetShort}
  '';

  # Assert secure primary and explicit tailnet-only HTTP fallback on every boot.
  serveAssert = pkgs.writeShellScript "tailscale-serve-assert" ''
    set -u
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.tailscale]}
    SOCK=/run/tailscale/tailscaled.sock
    for _ in ''$(seq 1 60); do
      if tailscale --socket=''$SOCK serve --bg --https 443 http://127.0.0.1:${toString port} 2>/dev/null \
        && tailscale --socket=''$SOCK serve --bg --http ${toString port} http://127.0.0.1:${toString port} 2>/dev/null; then
        echo "tailscale-serve: asserted https 443 + http ${toString port} -> 127.0.0.1:${toString port}"
        exit 0
      fi
      sleep 2
    done
    echo "tailscale-serve: could not assert serve (is Serve enabled in the admin console?)" >&2
    exit 1
  '';
in {
  environment.systemPackages = [dsh];

  finit.services.dsh-web = {
    description = "DeepSeek Harness web server (always-on, tailnet)";
    user = user;
    group = "users";
    command = webCommand;
    environment = {
      HOME = home;
      DSH_HOME = "${home}/.dsh";
    };
    conditions = ["net/lo/up" "net/tailscale0/up"];
    log = true;
  };

  finit.tasks.tailscale-serve = {
    description = "assert tailscale serve (dsh-web HTTPS + HTTP fallback)";
    conditions = ["net/tailscale0/up"];
    command = serveAssert;
    log = true;
  };
}
