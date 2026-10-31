{ lib, pkgs, omp, runner, user ? "y0usaf" }:
let
  key = ./id_ed25519;
  wrapper = pkgs.writeShellScriptBin "omp" ''
    set -eu
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/omp-box"
    key="$state/id_ed25519"
    if [ ! -f "$key" ]; then
      mkdir -p "$state"
      install -m 600 ${key} "$key"
    fi
    env_prefix=""
    for v in AI_GATEWAY_API_KEY ANTHROPIC_API_KEY OPENAI_API_KEY OPENROUTER_API_KEY GEMINI_API_KEY VERCEL_PERSONAL_TOKEN; do
      eval "value=\''${''${v}:-}"
      [ -n "$value" ] && env_prefix="$env_prefix$v=$(printf %q "$value") "
    done
    tty=-T
    [ -t 0 ] && [ -t 1 ] && tty=-t
    exec ${pkgs.openssh}/bin/ssh -q -p 22422 -i "$key" \
      -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes -o SendEnv=TERM $tty ${user}@127.0.0.1 \
      "exec sh -c $(printf %q "cd $(printf %q "$PWD") && exec env $env_prefix${omp}/bin/omp $(for a in "$@"; do printf %q "$a"; printf ' '; done)")"
  '';
in
pkgs.symlinkJoin {
  name = "omp-box";
  paths = [
    wrapper
    (pkgs.writeShellScriptBin "omp-host" ''exec ${omp}/bin/omp "$@"'')
  ];
}
