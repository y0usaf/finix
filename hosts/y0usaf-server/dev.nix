{
  config,
  pkgs,
  flakeInputs,
  ...
}: {
  environment = {
    variables = {
      HERMES_HOME = "/home/y0usaf/.hermes";
      HERMES_HEADLESS = "1";
    };
    systemPackages = [
      flakeInputs.hermes-agent.packages."${pkgs.stdenv.hostPlatform.system}".default
      (pkgs.writeShellApplication {
        name = "hermes-codex-auth";
        runtimeInputs = [pkgs.python3];
        text = ''
          set -euo pipefail

          if [[ "''${1:-}" != "--import-codex-cli" ]]; then
            printf 'Starting Hermes-owned Codex OAuth (device code).\n'
            printf 'Use --import-codex-cli only as a fallback; shared Codex CLI refresh tokens can be invalidated by codex/VS Code.\n\n'
            exec env HERMES_HEADLESS=1 hermes auth add openai-codex
          fi

          shift

          codex_home="''${CODEX_HOME:-$HOME/.codex}"
          hermes_home="''${HERMES_HOME:-$HOME/.hermes}"
          codex_auth="$codex_home/auth.json"
          hermes_auth="$hermes_home/auth.json"

          if [[ ! -r "$codex_auth" ]]; then
            printf 'missing %s\n' "$codex_auth" >&2
            printf 'run: codex login\n' >&2
            exit 1
          fi

          python3 - "$codex_auth" "$hermes_auth" <<'PY'
          import json
          import os
          import sys
          import tempfile
          from datetime import datetime, timezone
          from pathlib import Path

          codex_auth = Path(sys.argv[1]).expanduser()
          hermes_auth = Path(sys.argv[2]).expanduser()

          src = json.loads(codex_auth.read_text(encoding="utf-8"))
          tokens = src.get("tokens")
          if not isinstance(tokens, dict) or not tokens.get("access_token") or not tokens.get("refresh_token"):
              raise SystemExit(f"{codex_auth} does not contain usable Codex OAuth tokens")

          hermes_auth.parent.mkdir(parents=True, exist_ok=True)
          try:
              os.chmod(hermes_auth.parent, 0o700)
          except OSError:
              pass

          if hermes_auth.exists():
              try:
                  store = json.loads(hermes_auth.read_text(encoding="utf-8"))
              except json.JSONDecodeError as exc:
                  corrupt = hermes_auth.with_suffix(".json.corrupt")
                  corrupt.write_text(hermes_auth.read_text(encoding="utf-8"), encoding="utf-8")
                  print(f"preserved corrupt auth store at {corrupt}", file=sys.stderr)
                  store = {"version": 1, "providers": {}}
          else:
              store = {"version": 1, "providers": {}}

          providers = store.setdefault("providers", {})
          state = providers.setdefault("openai-codex", {})
          state["tokens"] = tokens
          state["last_refresh"] = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
          state["auth_mode"] = "chatgpt"
          store["active_provider"] = "openai-codex"
          store["version"] = 1
          store["updated_at"] = datetime.now(timezone.utc).isoformat()

          fd, tmp_name = tempfile.mkstemp(prefix="auth.json.tmp.", dir=str(hermes_auth.parent), text=True)
          try:
              with os.fdopen(fd, "w", encoding="utf-8") as handle:
                  json.dump(store, handle, indent=2)
                  handle.write("\n")
                  handle.flush()
                  os.fsync(handle.fileno())
              os.chmod(tmp_name, 0o600)
              os.replace(tmp_name, hermes_auth)
          finally:
              try:
                  os.unlink(tmp_name)
              except FileNotFoundError:
                  pass

          print(f"imported Codex OAuth → {hermes_auth}")
          PY

          if command -v hermes >/dev/null 2>&1; then
            if ! hermes config set model.provider openai-codex \
              || ! hermes config set model.default "''${HERMES_CODEX_MODEL:-gpt-5.5}" \
              || ! hermes config set model.base_url "''${HERMES_CODEX_BASE_URL:-https://chatgpt.com/backend-api/codex}"; then
              printf 'warning: could not edit Hermes config (likely Nix-managed); rebuild applies openai-codex config.\n' >&2
            fi
          fi

          printf 'test: hermes chat --provider openai-codex --model %s\n' "''${HERMES_CODEX_MODEL:-gpt-5.5}"
        '';
      })
    ];
  };

  manzil.users."${config.user.name}".files.".hermes/config.yaml".text = ''
    model:
      provider: openai-codex
      default: gpt-5.5
      base_url: https://chatgpt.com/backend-api/codex
      context_length: 256000

    agent:
      max_turns: 90

    terminal:
      backend: local
      cwd: .
      timeout: 180

    compression:
      enabled: true
      threshold: 0.50
      target_ratio: 0.20

    display:
      personality: professional
      show_reasoning: false
      show_cost: false
  '';

  user.dev = {
    claude-code = {
      enable = true;
      model = "sonnet";
      subagentModel = "sonnet";
      enabledPlugins."audio-notify@y0usaf-marketplace" = false;
    };
    codex = {
      enable = true;
      settings.personality = "pragmatic";
    };
    codex-cli.enable = true;
    pi.enable = true;
    nvim.enable = true;
    docker.enable = true;
  };
}
