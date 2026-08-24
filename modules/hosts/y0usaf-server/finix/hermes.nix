# Hermes Agent (NousResearch) as a finix-native service.
#
# Upstream ships only a NixOS module (systemd + optional OCI container). The
# server runs finix (finit pid1) and deliberately dropped docker/podman, so we
# replicate the native-service surface here: stateDir /var/lib/hermes bound
# from /persist, HERMES_HOME=$stateDir/.hermes, declarative config.yaml, and
# secret injection via $HERMES_HOME/.env (hermes reads it on startup).
#
# Interactive surface: `hermes` runs as the invoking user against per-user
# ~/.hermes (seeded with the same provider config + key by hermes-dirs), so
# workspace/git access works. `hermes-gw` (sudo -u hermes) administers the
# gateway's own state, which hermes clamps to 0700 at startup.
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
{
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  hermes = flakeInputs.hermes-agent.packages.${system}.minimal;
  stateDir = "/var/lib/hermes";

  # Interactive CLI runs as the invoking user with per-user ~/.hermes
  # (seeded by hermes-dirs below): a coding agent must run as the user
  # whose files it edits. The previous sudo-wrapper ran as `hermes` and
  # died stat'ing $PWD/.git under the 0700 /home/y0usaf. Gateway-state
  # admin (config set etc.) goes through hermes-gw instead.
  hermesGw = pkgs.writeShellScriptBin "hermes-gw" ''
    exec sudo -u hermes HOME=${stateDir} HERMES_HOME=${homeDir} ${hermes}/bin/hermes "$@"
  '';
  homeDir = "${stateDir}/.hermes";

  # Shared provider config (gateway + per-user CLI both seed this).
  baseConfig = {
    model = {
      default = "anthropic/claude-fable-5";
      provider = "ai-gateway";
    };
    # The CLI session/model-switch resolver (resolve_provider_full) only
    # knows config `providers:` — it never sees $HERMES_HOME user plugins.
    # The plugin below still feeds runtime quirks (auth-kind, headers,
    # model listing); this entry is what makes provider resolution work.
    providers.ai-gateway = {
      name = "Vercel AI Gateway";
      base_url = "https://ai-gateway.vercel.sh/v1";
      key_env = "AI_GATEWAY_API_KEY";
    };
  };

  # Gateway config: base + Aphrodite CCR context engine. `plugins.enabled`
  # activates the plugin (the imperative `hermes plugins enable aphrodite`
  # writes exactly this key); `context.engine` hands the compression engine
  # to the plugin; engine_threshold_pct = compress at 55% context fill
  # (plugin default 45, README recommends 55). model.context_length is
  # deliberately NOT set: claiming 1M tokens to a backend behind
  # the Vercel gateway needs testing before we trust it.
  configYaml = (pkgs.formats.yaml {}).generate "hermes-config.yaml" (baseConfig
    // {
      plugins.enabled = ["aphrodite" "serverstats"];
      context = {
        engine = "aphrodite";
        engine_threshold_pct = 55;
      };
    });

  # Per-user interactive CLI config stays bare: no plugins.enabled without a
  # seeded plugin dir, and the interactive surface doesn't run the proxies.
  configYamlUser = (pkgs.formats.yaml {}).generate "hermes-config-user.yaml" baseConfig;

  # Aphrodite CCR compression plugin (github:PlayForm/Aphrodite-Hermes).
  # The stock install auto-fetches binary + dylib from GitHub Releases via
  # download.sh (needs curl/wget and writes into the plugin dir — both wrong
  # on NixOS). Instead we pin the exact release the plugin's BINARY_VERSION
  # expects (1.3.7) and verify against the published SHA256SUMS file.
  aphroditeSrc = flakeInputs.aphrodite-hermes;
  aphroditeBin = pkgs.fetchurl {
    url = "https://github.com/PlayForm/Aphrodite/releases/download/Aphrodite%2Fv1.3.7/aphrodite-x86_64-unknown-linux-gnu";
    hash = "sha256-MfvWjkWGAwxRc9tbTNXNVzDfQ3E/KAOscG7SW9Xy1MQ=";
  };
  aphroditeLib = pkgs.fetchurl {
    url = "https://github.com/PlayForm/Aphrodite/releases/download/Aphrodite%2Fv1.3.7/libaphrodite_hermes-x86_64-unknown-linux-gnu.so";
    hash = "sha256-cDN0iz5P/pF8ZK3xWMFptfiEHUnUPuHAfmsLwaBptFo=";
  };
  # Python with PyYAML for the idempotent config merge below (the seed task
  # installs config.yaml only on first boot; the merge adds the aphrodite
  # keys to a live config.yaml without clobbering anything else).
  pyYaml = pkgs.python3.withPackages (ps: [ps.pyyaml]);
  aphroditeConfigMerge = pkgs.writeText "aphrodite-config-merge.py" ''
    import sys
    import yaml

    p = sys.argv[1]
    with open(p) as f:
        cfg = yaml.safe_load(f) or {}
    # Append, don't replace: preserve plugins enabled imperatively (e.g.
    # serverstats) so the declarative merge never drops them on a reboot.
    enabled = cfg.setdefault("plugins", {}).setdefault("enabled", [])
    if "aphrodite" not in enabled:
        enabled.append("aphrodite")
    ctx = cfg.setdefault("context", {})
    ctx["engine"] = "aphrodite"
    ctx["engine_threshold_pct"] = 55
    with open(p, "w") as f:
        yaml.safe_dump(cfg, f, sort_keys=False)
  '';

  # Persistent Bot Mode specialists. Their exact model route and membership
  # are declarative; mutable sessions, memories, and other profile metadata
  # remain runtime state under $HERMES_HOME/profiles/<name>.
  botProfiles = [
    {
      name = "deepseek-v4-pro-0813";
      title = "DeepSeek V4 Pro 0813";
      model = "deepseek/deepseek-v4-pro-0813";
      description = "DeepSeek V4 Pro 0813 specialist for deep technical reasoning, implementation, and independent review.";
    }
    {
      name = "opus-5";
      title = "Opus 5";
      model = "anthropic/claude-opus-5";
      description = "Claude Opus 5 specialist for architecture, rigorous review, and complex software-engineering decisions.";
    }
  ];
  botGroup = "Technical Council";
  botProfilesJson = pkgs.writeText "hermes-bot-profiles.json" (builtins.toJSON {
    inherit botGroup botProfiles;
    botGroupMembers = ["sol"] ++ map (bot: bot.name) botProfiles;
  });
  botProfilesMerge = pkgs.writeText "hermes-bot-profiles-merge.py" ''
    import os
    import shutil
    import sys
    import yaml

    home, definitions_path = sys.argv[1:3]
    with open(definitions_path, encoding="utf-8") as f:
        definitions = yaml.safe_load(f)

    group = definitions["botGroup"]
    profiles = definitions["botProfiles"]
    group_members = definitions["botGroupMembers"]
    source_env = os.path.join(home, ".env")
    source_skills = os.path.join(home, "skills")
    source_provider = os.path.join(home, "plugins", "model-providers", "ai-gateway")

    for bot in profiles:
        profile = os.path.join(home, "profiles", bot["name"])
        os.makedirs(profile, exist_ok=True)

        config_path = os.path.join(profile, "config.yaml")
        try:
            with open(config_path, encoding="utf-8") as f:
                config = yaml.safe_load(f) or {}
        except FileNotFoundError:
            # A first-boot profile inherits the managed gateway's complete
            # non-secret config (tools/plugins/context); subsequent boots
            # preserve its profile-local mutable settings.
            with open(os.path.join(home, "config.yaml"), encoding="utf-8") as f:
                config = yaml.safe_load(f) or {}
        config["model"] = {
            "default": bot["model"],
            "provider": "ai-gateway",
        }
        config.setdefault("providers", {})["ai-gateway"] = {
            "name": "Vercel AI Gateway",
            "base_url": "https://ai-gateway.vercel.sh/v1",
            "key_env": "AI_GATEWAY_API_KEY",
        }
        with open(config_path, "w", encoding="utf-8") as f:
            yaml.safe_dump(config, f, sort_keys=False)
        os.chmod(config_path, 0o660)

        meta_path = os.path.join(profile, "profile.yaml")
        try:
            with open(meta_path, encoding="utf-8") as f:
                meta = yaml.safe_load(f) or {}
        except FileNotFoundError:
            meta = {}
        meta["description"] = bot["description"]
        meta["description_auto"] = False
        ui = meta.setdefault("ui_meta", {}).setdefault("hermes-bots", {})
        ui["title"] = bot["title"]
        groups = [g for g in ui.get("groups", []) if isinstance(g, str) and g]
        if group not in groups:
            groups.append(group)
        ui["groups"] = groups
        ui["group"] = groups[0]
        with open(meta_path, "w", encoding="utf-8") as f:
            yaml.safe_dump(meta, f, sort_keys=False)

        if os.path.isfile(source_env):
            shutil.copy2(source_env, os.path.join(profile, ".env"))
            os.chmod(os.path.join(profile, ".env"), 0o600)
        if os.path.isdir(source_skills) and not os.path.exists(os.path.join(profile, "skills")):
            shutil.copytree(source_skills, os.path.join(profile, "skills"))
        if os.path.isdir(source_provider):
            target_provider = os.path.join(profile, "plugins", "model-providers", "ai-gateway")
            os.makedirs(os.path.dirname(target_provider), exist_ok=True)
            shutil.copytree(source_provider, target_provider, dirs_exist_ok=True)

    # Existing named profiles can participate without having their own model
    # routing changed. This seats Sol alongside the two specialists.
    for name in group_members:
        profile = os.path.join(home, "profiles", name)
        if not os.path.isdir(profile):
            continue
        meta_path = os.path.join(profile, "profile.yaml")
        try:
            with open(meta_path, encoding="utf-8") as f:
                meta = yaml.safe_load(f) or {}
        except FileNotFoundError:
            meta = {}
        ui = meta.setdefault("ui_meta", {}).setdefault("hermes-bots", {})
        groups = [g for g in ui.get("groups", []) if isinstance(g, str) and g]
        if group not in groups:
            groups.append(group)
        ui["groups"] = groups
        ui["group"] = groups[0]
        with open(meta_path, "w", encoding="utf-8") as f:
            yaml.safe_dump(meta, f, sort_keys=False)
  '';

  # serverstats dashboard plugin (desktop "Server Stats" pane): served by
  # hermes-dashboard at /api/plugins/serverstats/* — pure /proc stats, no deps.
  serverstatsManifest = pkgs.writeText "serverstats-manifest.json" ''
    {
      "name": "serverstats",
      "version": "0.1.0",
      "description": "Live finix server stats (CPU / RAM / disk / top procs) for the Hermes desktop UI",
      "api": "plugin_api.py"
    }
  '';
  serverstatsApi = pkgs.writeText "serverstats-plugin_api.py" ''
    """serverstats — live stats for the finix server, served to the Hermes desktop UI.

    Pure /proc reads (no psutil). Mounted by the hermes dashboard web server at
    /api/plugins/serverstats/* (see `_mount_plugin_api_routes` in web_server.py).

    Endpoints:
        GET /health -> {"ok": true}
        GET /stats  -> full snapshot: cpu%, load, mem, swap, disk, uptime, top procs
    """
    from __future__ import annotations

    import os
    import time
    from typing import Any, Dict, Optional

    from fastapi import APIRouter

    router = APIRouter()

    _HOST = os.uname().nodename
    _CORES = os.cpu_count() or 1
    _PAGE = os.sysconf("SC_PAGE_SIZE")

    # CPU samples are cached ~1.5s so concurrent pollers (chip + pane) share
    # one /proc/stat delta instead of each sleeping for the sample window.
    _cpu_cache: Dict[str, Any] = {"ts": 0.0, "val": 0.0}


    def _read(path: str) -> str:
        try:
            with open(path, "r") as f:
                return f.read()
        except OSError:
            return ""


    def _cpu_sample() -> tuple[int, int]:
        """Return (total_ticks, idle_ticks) from the first /proc/stat line."""
        lines = _read("/proc/stat").splitlines()
        if not lines:
            return (0, 0)
        parts = lines[0].split()
        nums = [int(x) for x in parts[1:] if x.isdigit()][:8]
        if len(nums) < 4:
            return (0, 0)
        idle = nums[3] + (nums[4] if len(nums) > 4 else 0)  # idle + iowait
        return (sum(nums), idle)


    def _compute_cpu(interval: float = 0.4) -> float:
        t0, i0 = _cpu_sample()
        if t0 == 0:
            return 0.0
        time.sleep(interval)
        t1, i1 = _cpu_sample()
        dt = t1 - t0
        if dt <= 0:
            return 0.0
        busy = (t1 - i1) - (t0 - i0)
        return round(min(100.0, max(0.0, 100.0 * busy / dt)), 1)


    def _cpu_percent() -> float:
        now = time.monotonic()
        if now - _cpu_cache["ts"] < 1.5:
            return _cpu_cache["val"]
        val = _compute_cpu(0.4)
        _cpu_cache["ts"] = now
        _cpu_cache["val"] = val
        return val


    def _meminfo() -> Dict[str, int]:
        info: Dict[str, int] = {}
        for line in _read("/proc/meminfo").splitlines():
            key, _, rest = line.partition(":")
            num = rest.split()[0]
            if num.isdigit():
                info[key] = int(num) * 1024
        return info


    def _disk(path: str) -> Optional[Dict[str, Any]]:
        try:
            st = os.statvfs(path)
            total = st.f_blocks * st.f_frsize
            avail = st.f_bavail * st.f_frsize
            pct = (100.0 * (st.f_blocks - st.f_bavail) / st.f_blocks
                   if st.f_blocks else 0.0)
            return {
                "path": path,
                "total": total,
                "used": total - avail,
                "available": avail,
                "percent": round(pct, 1),
            }
        except OSError:
            return None


    def _top_procs(limit: int = 6) -> list[Dict[str, Any]]:
        procs: list[Dict[str, Any]] = []
        for entry in os.listdir("/proc"):
            if not entry.isdigit():
                continue
            try:
                statm = _read(f"/proc/{entry}/statm").split()
                comm = _read(f"/proc/{entry}/comm").strip()
                if not statm:
                    continue
                rss = int(statm[1]) * _PAGE
                procs.append({"pid": int(entry), "name": comm or entry, "rss": rss})
            except (ValueError, OSError):
                continue
        procs.sort(key=lambda p: p["rss"], reverse=True)
        return procs[:limit]


    def _loadavg() -> Dict[str, float]:
        parts = _read("/proc/loadavg").split()
        if len(parts) < 3:
            return {"1": 0.0, "5": 0.0, "15": 0.0}
        return {"1": float(parts[0]), "5": float(parts[1]), "15": float(parts[2])}


    def _uptime() -> float:
        parts = _read("/proc/uptime").split()
        return float(parts[0]) if parts else 0.0


    @router.get("/health")
    def health() -> dict:
        return {"ok": True, "host": _HOST, "ts": int(time.time())}


    @router.get("/stats")
    def stats() -> dict:
        mem = _meminfo()
        total = mem.get("MemTotal", 0)
        avail = mem.get("MemAvailable", mem.get("MemFree", 0))
        swap_total = mem.get("SwapTotal", 0)
        swap_free = mem.get("SwapFree", 0)
        return {
            "host": _HOST,
            "cores": _CORES,
            "cpu_percent": _cpu_percent(),
            "load": _loadavg(),
            "mem": {
                "total": total,
                "available": avail,
                "used": max(0, total - avail),
                "percent": round(100.0 * (total - avail) / total, 1) if total else 0.0,
                "swap_total": swap_total,
                "swap_used": max(0, swap_total - swap_free),
            },
            "disk_persist": _disk("/persist"),
            "uptime_s": _uptime(),
            "top_procs": _top_procs(6),
            "ts": int(time.time()),
        }
  '';

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
  # No HERMES_HOME env plumbing: rush reads /etc/profile via
  # ~/.config/rush/profile.rush, and the wrapper carries the env itself.
  environment.systemPackages = [hermes hermesGw];

  fileSystems."${stateDir}" = {
    device = "/persist${stateDir}";
    fsType = "btrfs";
    options = ["bind"];
    neededForBoot = true;
  };

  users = {
    users.hermes = {
      isSystemUser = true;
      group = "hermes";
      home = stateDir;
    };
    users.y0usaf.extraGroups = ["hermes"];
    groups.hermes = {};
  };

  # Root-side seed: dirs, first-boot config.yaml, the ai-gateway provider
  # plugin, and AI_GATEWAY_API_KEY into .env from
  # /persist/secrets/hermes/ai-gateway-api-key. Idempotent.
  finit.tasks."hermes-dirs" = {
    description = "prepare hermes state dirs and seed config/env";
    command = pkgs.writeShellScript "hermes-dirs" ''
      set -eu
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gnugrep]}
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

      # Declarative serverstats dashboard plugin (desktop "Server Stats" pane):
      # served by hermes-dashboard at /api/plugins/serverstats/*, allow-listed
      # via plugins.enabled (configYaml + the merge above).
      mkdir -p ${homeDir}/plugins/serverstats/dashboard
      install -o hermes -g hermes -m 0644 ${serverstatsManifest} \
        ${homeDir}/plugins/serverstats/dashboard/manifest.json
      install -o hermes -g hermes -m 0644 ${serverstatsApi} \
        ${homeDir}/plugins/serverstats/dashboard/plugin_api.py

      # Aphrodite CCR compression plugin: writable copy of the plugin tree +
      # pinned, hash-verified binaries. Pre-placing them means download.sh
      # (curl/wget, writes into the plugin dir) is never needed at runtime.
      # Idempotent: cp/install overwrite each boot, so a bumped pin reseeds
      # on the next switch.
      mkdir -p ${homeDir}/plugins/aphrodite/binaries
      cp -rT ${aphroditeSrc} ${homeDir}/plugins/aphrodite
      install -m 0755 ${aphroditeBin} \
        ${homeDir}/plugins/aphrodite/binaries/aphrodite
      install -m 0644 ${aphroditeLib} \
        ${homeDir}/plugins/aphrodite/binaries/libaphrodite_hermes-x86_64-unknown-linux-gnu.so
      chown -R hermes:hermes ${homeDir}/plugins/aphrodite
      chmod 2770 ${homeDir}/plugins/aphrodite
      # Idempotent merge of the aphrodite keys into an existing config.yaml
      # (the generated file only installs on first boot; this keeps live
      # tweaks while adding the declarative keys).
      ${pyYaml}/bin/python3 ${aphroditeConfigMerge} ${homeDir}/config.yaml

      chmod 0660 ${homeDir}/config.yaml 2>/dev/null || true
      chown -R hermes:hermes ${homeDir} 2>/dev/null || true
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
      # Dashboard basic-auth (hermes desktop remote backend): same idempotent
      # pattern as the API key; secrets from /persist/secrets/hermes/.
      for var in HERMES_DASHBOARD_BASIC_AUTH_USERNAME HERMES_DASHBOARD_BASIC_AUTH_PASSWORD HERMES_DASHBOARD_BASIC_AUTH_SECRET; do
        secret=/persist/secrets/hermes/dashboard-auth-$var
        if [ -r "$secret" ] && { [ ! -f ${homeDir}/.env ] || ! grep -q "^$var=" ${homeDir}/.env 2>/dev/null; }; then
          printf '%s=%s\n' "$var" "$(tr -d '\r\n' < "$secret")" >> ${homeDir}/.env
        fi
      done
      # Per-user interactive state for y0usaf: same provider config + key,
      # own ~/.hermes. hermes itself clamps it to 0700 at startup; running
      # as y0usaf keeps workspace file access intact while the gateway's
      # state stays private to the hermes user.
      uhome=/home/y0usaf/.hermes
      mkdir -p $uhome/plugins/model-providers/ai-gateway
      if [ ! -f $uhome/config.yaml ]; then
        install -m 0600 ${configYamlUser} $uhome/config.yaml
      fi
      install -m 0644 ${aiGatewayProviderPy} \
        $uhome/plugins/model-providers/ai-gateway/__init__.py
      if [ -r "$secret" ] && { [ ! -f $uhome/.env ] || ! grep -q '^AI_GATEWAY_API_KEY=' $uhome/.env 2>/dev/null; }; then
        key="$(tr -d '\r\n' < "$secret")"
        tmp=$uhome/.env.tmp
        { echo "AI_GATEWAY_API_KEY=$key"; grep -v '^AI_GATEWAY_API_KEY=' $uhome/.env 2>/dev/null || true; } > "$tmp"
        mv "$tmp" $uhome/.env
        chmod 0600 $uhome/.env
      fi
      chown -R y0usaf:users $uhome 2>/dev/null || true
      # Create/update the declarative specialist profiles only after the
      # shared credential and plugin sources have been seeded. The merge owns
      # model routing, role/title, and Technical Council membership; sessions
      # and memories remain mutable runtime state.
      mkdir -p ${homeDir}/profiles
      ${pyYaml}/bin/python3 ${botProfilesMerge} ${homeDir} ${botProfilesJson}

      # Idempotent belt-and-suspenders: fix a pre-existing 0600 .env on next
      # boot (only reachable via the re-write branch above otherwise).
      chmod 0640 ${homeDir}/.env 2>/dev/null || true
      chmod 0660 ${homeDir}/config.yaml 2>/dev/null || true
      chown -R hermes:hermes ${homeDir} 2>/dev/null || true
    '';
    log = true;
  };

  finit.services."hermes-gateway" = {
    description = "hermes agent gateway (Vercel AI Gateway provider)";
    user = "hermes";
    group = "hermes";
    command = "${pkgs.writeShellScript "hermes-gateway-start" ''
      set -eu
      export PATH=${lib.makeBinPath [pkgs.coreutils]}
      exec ${hermes}/bin/hermes gateway run
    ''}";
    environment = {
      HOME = stateDir;
      HERMES_HOME = homeDir;
      HERMES_MANAGED = "true";
      # The Rust dylib needs libstdc++.so.6, absent from the minimal loader
      # path (verified 2026-08-02: ctypes.CDLL of the plugin dylib fails
      # with "libstdc++.so.6: cannot open shared object file" until the gcc
      # lib dir is on the loader path). Fixes the dylib and the proxy binary.
      LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
      # Aphrodite: explicit binary/dylib paths (same as the plugin's
      # defaults; explicit = self-documenting and guarantees the finit unit
      # restarts on deploy so the hooks load).
      APHRODITE_BINARY_PATH = "${homeDir}/plugins/aphrodite/binaries/aphrodite";
      APHRODITE_HERMES_DYLIB_PATH = "${homeDir}/plugins/aphrodite/binaries/libaphrodite_hermes-x86_64-unknown-linux-gnu.so";
    };
    conditions = ["net/lo/up" "task/hermes-dirs/success"];
    log = true;
  };

  finit.services."hermes-dashboard" = {
    description = "hermes web dashboard (desktop remote backend)";
    user = "hermes";
    group = "hermes";
    command = "${pkgs.writeShellScript "hermes-dashboard-start" ''
      set -eu
      export PATH=${lib.makeBinPath [pkgs.coreutils]}
      exec ${hermes}/bin/hermes dashboard --host 0.0.0.0 --port 9119 --no-open
    ''}";
    environment = {
      HOME = stateDir;
      HERMES_HOME = homeDir;
      HERMES_MANAGED = "true";
      # Same loader-path + explicit binary/dylib paths as the gateway: the
      # dashboard shares $HERMES_HOME/config.yaml (plugins.enabled) so it
      # also loads plugins; without these it fails on the short-name default
      # dylib lookup + the missing libstdc++ (both seen in the 08-02 logs).
      LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
      APHRODITE_BINARY_PATH = "${homeDir}/plugins/aphrodite/binaries/aphrodite";
      APHRODITE_HERMES_DYLIB_PATH = "${homeDir}/plugins/aphrodite/binaries/libaphrodite_hermes-x86_64-unknown-linux-gnu.so";
    };
    conditions = ["net/lo/up" "task/hermes-dirs/success"];
    log = true;
  };
}
