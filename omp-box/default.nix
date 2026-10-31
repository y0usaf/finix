{ lib, pkgs, omp, shares ? [], user ? "y0usaf" }:
let
  key = ./id_ed25519;
  staticArms = lib.concatMapStringsSep "\n    " (p: ''case "$PWD/" in ${p}/*) allowed=1 ;; esac'') shares;
  wrapper = pkgs.writeShellScriptBin "omp" ''
    set -eu
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/omp-box"
    key="$state/id_ed25519"
    if [ ! -f "$key" ]; then
      mkdir -p "$state"
      install -m 600 ${key} "$key"
    fi
    allowed=0
    ${staticArms}
    if [ -d "$state/grants" ]; then
      for grant in "$state/grants"/*; do
        [ -e "$grant" ] || continue
        granted=$(cut -f1 "$grant")
        case "$PWD/" in "$granted"/*) allowed=1 ;; esac
      done
    fi
    seed=""
    if [ "$allowed" != 1 ]; then
      base="''${PWD%/}"
      hint=" (omp-box add $PWD to share it)"
      case "$HOME/" in "$base"/*) hint=" (omp-box add a folder inside it to share)" ;; esac
      case "$state/" in "$base"/*) hint=" (omp-box add a folder inside it to share)" ;; esac
      printf 'omp-box: %s is the box copy, not the host folder%s\n' "$PWD" "$hint" >&2
      seed="mkdir -p $(printf %q "$PWD") && "
    fi
    env_prefix=""
    for v in AI_GATEWAY_API_KEY OPENROUTER_API_KEY CELERIS_API_KEY ANTHROPIC_API_KEY OPENAI_API_KEY GEMINI_API_KEY; do
      eval "value=\''${''${v}:-}"
      if [ -z "$value" ] && [ -r "$HOME/Tokens/$v.txt" ]; then value=$(cat "$HOME/Tokens/$v.txt"); fi
      [ -n "$value" ] && env_prefix="$env_prefix$v=$(printf %q "$value") "
    done
    tty=-T
    [ -t 0 ] && [ -t 1 ] && tty=-t
    exec ${pkgs.openssh}/bin/ssh -q -p 22422 -i "$key" \
      -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes -o SendEnv=TERM $tty ${user}@127.0.0.1 \
      "exec sh -c $(printf %q "$seed cd $(printf %q "$PWD") && exec env $env_prefix${omp}/bin/omp $(for a in "$@"; do printf %q "$a"; printf ' '; done)")"
  '';
  cli = pkgs.writeShellApplication {
    name = "omp-box";
    runtimeInputs = [ pkgs.coreutils pkgs.util-linux pkgs.openssh pkgs.findutils ];
    text = builtins.readFile ./omp-box.sh;
  };
in
pkgs.symlinkJoin {
  name = "omp-box";
  paths = [
    wrapper
    cli
    (pkgs.writeShellScriptBin "omp-host" ''exec ${omp}/bin/omp "$@"'')
  ];
}
