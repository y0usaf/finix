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
# Remote workspace (2026-08-25): the gateway + dashboard set
# terminal.backend=ssh, so THEIR tool calls execute on y0usaf-desktop
# (Tailscale 100.90.54.18, sshd :2222) instead of locally. Auth reuses the
# service account's /var/lib/hermes/.ssh/id_ed25519, which IS the desktop
# device key (hosts/y0usaf-desktop/user-ssh.pub) that
# hosts/common/ssh-keys.nix authorizes on every host — no extra keypair.
# The per-user interactive `hermes` CLI deliberately stays local-backend:
# a coding agent runs as the user whose files it edits (see below).
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
    # Declared 2026-08-31: reasoning_effort lives under agent., NOT model.
    # model.reasoning_effort is a DEAD key — hermes_constants.resolve_reasoning_config
    # reads agent.reasoning_effort on every surface and never model.*; with the key
    # under model. the resolver silently fell back to its default (medium), so the
    # gateway ran GLM-5.3-flash at medium thinking. GLM clamps ultra -> max on the
    # wire (GLM53_EFFORTS = low/medium/high/max), so this is the top GLM effort.
    agent.reasoning_effort = "ultra";
    # Declared 2026-08-31: approvals.mode=off — the fleet runs unattended
    # (gateway, cron, Bot Mode profiles), so approval prompts just queue with
    # nobody to answer them. Verified at v0.21.0 against
    # tools/approval.py: the mode=off bypass sits at the top of
    # check_dangerous_command and _run_approval_gate, ahead of the gateway
    # round-trip, cron_mode, single_query_mode, and command_allowlist checks.
    # The unconditional hardline floor (rm -rf /, mkfs, raw dd, shutdown,
    # fork bomb) and user approvals.deny rules still fire AFTER the bypass,
    # so this drops interactive prompts, not catastrophic-command protection.
    # Replaces the 2026-08-31 command_allowlist=["sudo *"] declaration, which
    # is dead under mode=off (the bypass returns before the allowlist runs).
    approvals.mode = "off";
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

  # Gateway config: Aphrodite is intentionally disabled; keep only the
  # serverstats plugin enabled.
  configYaml = (pkgs.formats.yaml {}).generate "hermes-config.yaml" (baseConfig
    // {
      plugins.enabled = ["serverstats"];
    });

  # Per-user interactive CLI config stays bare: no plugins.enabled without a
  # seeded plugin dir, and the interactive surface doesn't run the proxies.
  configYamlUser = (pkgs.formats.yaml {}).generate "hermes-config-user.yaml" baseConfig;

  # Upstream-style deep merge (port of hermes-agent nix/configMergeScript.nix,
  # rev 3783fd9): on EVERY hermes-dirs run, declarative baseConfig keys are
  # deep-merged into the live config.yaml — Nix keys win per-leaf, everything
  # else (runtime `hermes config set` writes, imperative tweaks) survives.
  # This replaces the old first-boot-only config install plus a pile of
  # per-key PyYAML merge scripts (reasoning-effort, ssh-workspace): those
  # existed because first-boot seeding never reached existing installs.
  configMergeScript = pkgs.writeText "hermes-config-merge.py" ''
    import json
    import sys

    import yaml

    nix_json, config_path = sys.argv[1], sys.argv[2]

    with open(nix_json) as f:
        nix = json.load(f)

    existing = {}
    try:
        with open(config_path) as f:
            existing = yaml.safe_load(f) or {}
    except FileNotFoundError:
        pass

    def deep_merge(base, override):
        result = dict(base)
        for k, v in override.items():
            if k in result and isinstance(result[k], dict) and isinstance(v, dict):
                result[k] = deep_merge(result[k], v)
            else:
                result[k] = v
        return result

    merged = deep_merge(existing, nix)
    with open(config_path, "w") as f:
        yaml.dump(merged, f, default_flow_style=False, sort_keys=False)
  '';

  # JSON rendering of baseConfig + the gateway-only keys (plugins.enabled,
  # terminal.backend=ssh remote workspace — see TERMINAL_SSH_* in the service
  # environments below), consumed by configMergeScript for the gateway
  # HERMES_HOME.
  gatewayConfigJson = pkgs.writeText "hermes-config-gateway.json" (builtins.toJSON
    (baseConfig // {
      plugins.enabled = ["serverstats"];
      terminal.backend = "ssh";
    }));
  # Per-user CLI config: bare baseConfig (no plugins without a seeded dir).
  userConfigJson = pkgs.writeText "hermes-config-user.json" (builtins.toJSON baseConfig);

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
  # Python with PyYAML for the config deep-merge (configMergeScript above)
  # and the bot-profiles merge below.
  pyYaml = pkgs.python3.withPackages (ps: [ps.pyyaml]);

  # Fleet personas: SOUL.md per bot, flake-owned. Rewritten into the profile
  # on every hermes-dirs run — sessions/memories stay mutable, personas do not.
  atlasSoul = pkgs.writeText "hermes-soul-atlas.md" ''
    # Atlas — Fleet Orchestrator

    You are **Atlas**, the orchestrator of a small fleet of specialist Hermes agents. You are the user's single point of contact: they talk to you, you make the work happen, you report back.

    ## Your fleet

    Delegate with `@name <task>` mentions; wait for replies and integrate them.

    - **@forge** — software implementation. Features, bugfixes, refactors in a target repo.
    - **@scout** — research. Web, docs, codebase exploration. Read-only.
    - **@wrench** — ops & automation. Shell tasks, scripts, environments, NixOS/Nix flakes, cron jobs.
    - **@sage** — review & QA gate. Independent diff review and test re-runs.

    ## Standing instructions

    1. **Decompose before delegating.** Break requests into slim, single-owner tasks. One bot per task; say which repo/directory applies.
    2. **Never let unverified work reach the user.** Any code change goes through @sage (review + re-run tests) before you report it done. A FAIL from sage means back to the drawing board, not a caveat in your report.
    3. **Decide, don't interrupt.** The user wants zero mid-task questions. Resolve ambiguity yourself, state your assumptions in the final report. Escalate to the user ONLY for irreversible/destructive actions outside the agreed scope (deleting data, pushing to shared remotes, spending money).
    4. **Respect repo law.** Bots follow each repo's own AGENTS.md. For CookUnity repos that means Linear tickets gate implementation — if no ticket exists, have scout/wrench prepare what's needed and surface that in your report rather than working around it.
    5. **Report like an engineer:** what was asked → what was done → evidence (test output, commands run, file paths) → assumptions made. Concise. No filler.
    6. **Do it yourself when it's smaller than the delegation.** Trivial lookups or one-liners don't need the fleet.
    7. Keep group-chat turns brief: state position, cite evidence, pass when you have nothing new.
  '';

  forgeSoul = pkgs.writeText "hermes-soul-forge.md" ''
    # Forge — Software Implementation

    You are **Forge**, the implementation specialist on a fleet orchestrated by **Atlas** (@atlas). You receive slim coding tasks, usually with a target repo/directory.

    ## Standing instructions

    1. **Read the repo's AGENTS.md (or CLAUDE.md) before touching anything.** It is law for that repo. CookUnity repos under `~/cu-workbench/repos/` require a Linear ticket before persisted changes — if none was given, stop and tell Atlas what's missing instead of committing anything.
    2. **Know the terrain.** Personal projects live in `~/dev` and `~/finix` (Nix flake project). Work repos in `~/cu-workbench/repos`. Match the repo's existing style, framework, and conventions.
    3. **Write less code.** Prefer deletion to addition; abstract only on the third use. Smallest change that fully solves the task.
    4. **Done means tested.** No task is complete until you've actually run the relevant tests/build/lint and can quote the passing output. If there are no tests, run the thing itself and prove it works. Report the exact command + result.
    5. **Stay in scope.** Fix the assigned task. Noticed unrelated breakage? Mention it in your reply, don't fix it silently.
    6. **Report back to whoever delegated** (usually @atlas): files changed, commands run, test evidence, anything you deliberately didn't do.
  '';

  sageSoul = pkgs.writeText "hermes-soul-sage.md" ''
    # Sage — Review & QA Gate

    You are **Sage**, the verification gate on a fleet orchestrated by **Atlas** (@atlas). Nothing reaches the user until you've checked it.

    ## Standing instructions

    1. **Verify independently.** Never trust the implementer's claim that tests pass. Re-run the tests/build/lint yourself and read the actual output. Reading a report is not verifying.
    2. **Review diffs like a hostile senior engineer.** Correctness first; then scope creep (unrelated changes), error handling, and repo-convention violations (check the repo's AGENTS.md). Flag security issues loudly.
    3. **Verdicts only:** end every review with exactly one line:
       - `VERDICT: PASS — <one-sentence justification>`
       - `VERDICT: FAIL — <what must change>`
       "Probably fine" is a FAIL. Inability to run the verification yourself is a FAIL with that reason.
    4. **No drive-by fixes.** You review and verify; you don't rewrite the code. Tell Forge *what* and *where* (`file:line`), not how you'd have written it — unless asked for a concrete suggestion.
    5. **Slim reports.** Blocking issues first, then non-blocking notes, then the verdict line.
    6. Reply to whoever delegated (usually @atlas).
  '';

  scoutSoul = pkgs.writeText "hermes-soul-scout.md" ''
    # Scout — Research

    You are **Scout**, the research specialist on a fleet orchestrated by **Atlas** (@atlas). You find things out and hand back verified answers.

    ## Standing instructions

    1. **Strictly read-only.** You research, explore, read, and analyze. You do not edit files, commit, install, or mutate anything. If a task turns into something that needs mutation, report findings and say so.
    2. **Answer first, sources attached.** Lead with the answer, then the evidence: URLs for web claims, `file:line` anchors for codebase claims, quoted command output for system claims. No unsupported assertions.
    3. **Cover both terrains.** Web/docs research AND local codebase exploration (`~/dev`, `~/finix`, `~/cu-workbench/repos` — for work repos consult `~/cu-workbench/architecture/` maps first).
    4. **Say "I couldn't verify" plainly** when that's the truth, and say what you tried. A wrong confident answer poisons the whole fleet.
    5. **Slim output.** Findings in bullets, each anchored. No essay unless asked.
    6. Reply to whoever delegated (usually @atlas).
  '';

  wrenchSoul = pkgs.writeText "hermes-soul-wrench.md" ''
    # Wrench — Ops & Automation

    You are **Wrench**, the ops/automation specialist on a fleet orchestrated by **Atlas** (@atlas). You handle the machine: shell tasks, scripts, environments, services, scheduling.

    ## Standing instructions

    1. **This machine runs finix** (a NixOS fork; no `nixos-version` binary). System changes go through Nix, not imperative hacks. System flake config lives in `~/finix`. Verification means `nix build` / `nix flake check` / `nix run` exiting zero — quote it. `cargo build` filling `target/` doesn't count.
    2. **Write less code.** Best automation is no automation; second best is easy to delete. Before writing a script, check whether a one-liner, an existing tool, or deletion does the job.
    3. **Fail loudly, stay silent on success.** Scripts you write print nothing when nothing went wrong and exit non-zero with a clear message on bad input.
    4. **Destructive = confirm first.** Even though Atlas avoids interrupting the user, YOU pause and kick back to Atlas before: deleting data, touching systemd units/services, changing firewall/network config, or anything irreversible beyond the stated task.
    5. **Recurring jobs** become Hermes cron jobs (namespaced `[bot:wrench] ...`), never stray crontabs, unless told otherwise.
    6. **Report back to the delegator** (usually @atlas): what ran, what changed, how it was verified.
  '';

  # Persistent Bot Mode specialists. Their exact model route and membership
  # are declarative; mutable sessions, memories, and other profile metadata
  # remain runtime state under $HERMES_HOME/profiles/<name>. Optional per-bot
  # fields: `group` (defaults to botGroup) and `soul` (store path written to
  # the profile's SOUL.md on every seed run).
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
    {
      name = "atlas";
      title = "Atlas";
      model = "zai/glm-5.3-flash";
      description = "Orchestrator and single point of contact. Decomposes requests, delegates to forge/scout/wrench/sage via mentions, verifies results, reports back.";
      group = "Atlas Fleet";
      soul = atlasSoul;
    }
    {
      name = "forge";
      title = "Forge";
      model = "openai/gpt-5.6-luna";
      description = "Software implementation specialist. Writes features and fixes in the target repo, follows repo AGENTS.md rules, tests before claiming done.";
      group = "Atlas Fleet";
      soul = forgeSoul;
    }
    {
      name = "sage";
      title = "Sage";
      model = "openai/gpt-5.6-luna";
      description = "Review and QA gate. Reviews diffs, re-runs tests independently, issues verdicts of PASS or FAIL only.";
      group = "Atlas Fleet";
      soul = sageSoul;
    }
    {
      name = "scout";
      title = "Scout";
      model = "openai/gpt-5.6-luna";
      description = "Research specialist. Web, docs, and codebase exploration with cited anchors. Strictly read-only.";
      group = "Atlas Fleet";
      soul = scoutSoul;
    }
    {
      name = "wrench";
      title = "Wrench";
      model = "openai/gpt-5.6-luna";
      description = "Ops and automation specialist. Shell tasks, scripts, environments, NixOS flakes, scheduled jobs. Prefers deleting code over adding it.";
      group = "Atlas Fleet";
      soul = wrenchSoul;
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

    default_group = definitions["botGroup"]
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
        # Unattended bots: no human answers approval prompts in profile
        # sessions. Same floor still applies (hardline + approvals.deny).
        config.setdefault("approvals", {})["mode"] = "off"
        config.setdefault("providers", {})["ai-gateway"] = {
            "name": "Vercel AI Gateway",
            "base_url": "https://ai-gateway.vercel.sh/v1",
            "key_env": "AI_GATEWAY_API_KEY",
        }
        # The live knob is agent.reasoning_effort (model.* is a dead key).
        config.setdefault("agent", {})["reasoning_effort"] = "ultra"
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
        group = bot.get("group", default_group)
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

        # Flake-owned persona: SOUL.md is rewritten from the declarative
        # source on every seed run (unlike sessions/memories, it is not
        # mutable runtime state).
        soul = bot.get("soul")
        if soul:
            shutil.copy2(soul, os.path.join(profile, "SOUL.md"))

    # Existing named profiles can participate without having their own model
    # routing changed. This seats Sol alongside the two specialists.
    for name in group_members:
        if any(bot["name"] == name for bot in profiles):
            continue  # fleet bots already carry their own group above
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
        if default_group not in groups:
            groups.append(default_group)
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

  # Root-side seed: dirs, config deep-merge, the ai-gateway provider
  # plugin, and AI_GATEWAY_API_KEY into .env from
  # /persist/secrets/hermes/ai-gateway-api-key. Idempotent.
  finit = {
    tasks."hermes-dirs" = {
      description = "prepare hermes state dirs and seed config/env";
      command = pkgs.writeShellScript "hermes-dirs" ''
              set -eu
              export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gnugrep pkgs.findutils]}
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
              # Always-run deep merge of declarative keys into the live gateway
              # config (Nix keys win per-leaf, runtime keys survive). Subsumes
              # the old per-key merge scripts: agent.reasoning_effort,
              # terminal.backend=ssh, approvals.mode all ride in via baseConfig.
              ${pyYaml}/bin/python3 ${configMergeScript} ${gatewayConfigJson} ${homeDir}/config.yaml
              chown hermes:hermes ${homeDir}/config.yaml
              chmod 0660 ${homeDir}/config.yaml
              # Managed-mode marker (upstream parity): interactive `hermes-gw`
              # shells see this (they don't inherit HERMES_MANAGED) and refuse
              # config writes the flake owns. "nixos" names the rebuild command.
              install -o hermes -g hermes -m 0644 ${pkgs.writeText "hermes-managed" "nixos"} ${homeDir}/.managed
              # Declarative ai-gateway provider profile (hermes user plugin).
              install -o hermes -g hermes -m 0644 ${aiGatewayProviderPy} \
                ${homeDir}/plugins/model-providers/ai-gateway/__init__.py

              # Declarative serverstats dashboard plugin (desktop "Server Stats" pane):
              # served by hermes-dashboard at /api/plugins/serverstats/*, allow-listed
              # via plugins.enabled (gatewayConfigJson -> deep merge above).
              mkdir -p ${homeDir}/plugins/serverstats/dashboard
              install -o hermes -g hermes -m 0644 ${serverstatsManifest} \
                ${homeDir}/plugins/serverstats/dashboard/manifest.json
              install -o hermes -g hermes -m 0644 ${serverstatsApi} \
                ${homeDir}/plugins/serverstats/dashboard/plugin_api.py

              # Aphrodite CCR compression plugin: writable copy of the plugin tree +
              # pinned, hash-verified binaries. Pre-placing them means download.sh
              # (curl/wget, writes into the plugin dir) is never needed at runtime.
              # Wipe + reseed each boot: the upstream tree carries dangling symlinks
              # (directives -> /Users/nikola/..., a macOS dev path) whose entry type
              # flips between source generations, and an in-place `cp -rT` fails
              # whenever the live entry's type no longer matches (both failure
              # directions seen in production: 08-25 symlink-vs-dir, 08-28 the
              # reverse). Reseeding from scratch is type-agnostic; pruning dangling
              # links afterwards keeps the tree importable.
              rm -rf ${homeDir}/plugins/aphrodite
              mkdir -p ${homeDir}/plugins/aphrodite/binaries
              cp -rT ${aphroditeSrc} ${homeDir}/plugins/aphrodite
              find ${homeDir}/plugins/aphrodite -xtype l -delete
              install -m 0755 ${aphroditeBin} \
                ${homeDir}/plugins/aphrodite/binaries/aphrodite
              install -m 0644 ${aphroditeLib} \
                ${homeDir}/plugins/aphrodite/binaries/libaphrodite_hermes-x86_64-unknown-linux-gnu.so
              chown -R hermes:hermes ${homeDir}/plugins/aphrodite
              chmod 2770 ${homeDir}/plugins/aphrodite

              # The service account's id_ed25519 IS the desktop device key
              # (hosts/y0usaf-desktop/user-ssh.pub), already authorized on every
              # host via hosts/common/ssh-keys.nix. Only the routing stanza is new;
              # appended after the github block, idempotent on re-runs.
              mkdir -p ${stateDir}/.ssh
              chmod 0700 ${stateDir}/.ssh
              if ! grep -q "hermes-workspace" ${stateDir}/.ssh/config 2>/dev/null; then
                cat >> ${stateDir}/.ssh/config <<'SSHCFG'

        Host hermes-workspace y0usaf-desktop desktop-ws
          HostName 100.90.54.18
          Port 2222
          User y0usaf
          IdentityFile /var/lib/hermes/.ssh/id_ed25519
          IdentitiesOnly yes
          StrictHostKeyChecking accept-new
        SSHCFG
                chown hermes:hermes ${stateDir}/.ssh/config
              fi

              # Restore the service-account SSH key from /persist/secrets if missing.
              # The key is the desktop device key (hosts/y0usaf-desktop/user-ssh.pub);
              # without it the gateway's ssh workspace (tool calls to the desktop)
              # dies with "Permission denied (publickey)". Idempotent — only writes
              # when the key is absent or empty, never overwrites a working one.
              ssh_secret=/persist/secrets/hermes/ssh-ed25519-key
              if [ -r "$ssh_secret" ] && { [ ! -s ${stateDir}/.ssh/id_ed25519 ] || ! head -1 ${stateDir}/.ssh/id_ed25519 2>/dev/null | grep -q 'PRIVATE KEY'; }; then
                install -m 0600 -o hermes -g hermes "$ssh_secret" ${stateDir}/.ssh/id_ed25519
              fi

              # Hermes' SSH backend keeps ControlMaster sockets under
              # /var/tmp/hermes-ssh/; it creates that dir as whoever runs first, so
              # make it sticky world-writable for multi-account sharing (gateway =
              # hermes user, interactive CLI = y0usaf).
              mkdir -p /var/tmp/hermes-ssh
              chmod 1777 /var/tmp/hermes-ssh

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
              # Same always-run deep merge for the interactive CLI config.
              ${pyYaml}/bin/python3 ${configMergeScript} ${userConfigJson} $uhome/config.yaml
              chown y0usaf:users $uhome/config.yaml
              chmod 0600 $uhome/config.yaml
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

    services."hermes-gateway" = {
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
        # Remote workspace: tools execute on y0usaf-desktop over SSH (keyed by
        # the desktop device key the service account already owns; stanza is
        # appended to its ~/.ssh/config by the hermes-dirs task below).
        TERMINAL_SSH_HOST = "100.90.54.18";
        TERMINAL_SSH_PORT = "2222";
        TERMINAL_SSH_USER = "y0usaf";
        TERMINAL_SSH_KEY = "${stateDir}/.ssh/id_ed25519";
      };
      conditions = ["net/lo/up" "task/hermes-dirs/success"];
      log = true;
    };

    services."hermes-dashboard" = {
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
        # Same remote workspace as the gateway (see comment there).
        TERMINAL_SSH_HOST = "100.90.54.18";
        TERMINAL_SSH_PORT = "2222";
        TERMINAL_SSH_USER = "y0usaf";
        TERMINAL_SSH_KEY = "${stateDir}/.ssh/id_ed25519";
      };
      conditions = ["net/lo/up" "task/hermes-dirs/success"];
      log = true;
    };
  };
}
