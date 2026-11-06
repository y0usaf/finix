{
  config,
  lib,
  pkgs,
  ...
}: let
  model = import ./ablit.data.nix;
  home = config.user.homeDirectory;
  dir = "${home}/${model.dir}";
  url = "http://127.0.0.1:${toString model.port}";
  # Serves the model omp-ablit picked (ablit.data.nix) from the 4090 for as long as one omp run lasts. The box's
  # QEMU user networking hands omp, which runs in the box, the host loopback as 10.0.2.2, so the box's provider
  # entry (box.nix) reaches this server and the LAN never does. --fit offloads as few layers to the CPU as the
  # free VRAM of the moment allows, so a running GPU job costs speed, not a failed start.
  omp-ablit = pkgs.writeShellApplication {
    name = "omp-ablit";
    runtimeInputs = [pkgs.coreutils pkgs.curl pkgs.llama-cpp];
    text = ''
      dir=${dir}
      file="$dir/${model.file}"
      log="$dir/llama-server.log"
      url=${url}

      mkdir -p "$dir"
      if [ ! -f "$file" ]; then
        echo "omp-ablit: fetching ${model.file} into $dir, once" >&2
        curl -fL --retry 5 -o "$file.part" ${model.url}
        echo "${model.sha256}  $file.part" | sha256sum -c -
        mv "$file.part" "$file"
      fi

      server=""
      vram() {
        command -v nvidia-smi >/dev/null 2>&1 || return 0
        [ -n "$server" ] || return 0
        nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader,nounits |
          awk -F', ' -v pid="$server" '$1 == pid {print "omp-ablit: llama-server holds " $2 " MiB of VRAM"}' >&2
      }
      timings() {
        [ -f "$log" ] || return 0
        grep -Eo '(prompt eval time|eval time) =.*' "$log" | tail -n 2 | sed 's/^/omp-ablit: /' >&2 || true
      }
      cleanup() {
        status=$?
        trap - EXIT
        vram
        if [ -n "$server" ]; then
          kill "$server" 2>/dev/null || true
          wait "$server" 2>/dev/null || true
        fi
        timings
        exit "$status"
      }
      trap cleanup EXIT

      if curl -fsS "$url/health" >/dev/null 2>&1; then
        echo "omp-ablit: using the llama-server another session already runs on $url" >&2
      else
        echo "omp-ablit: starting ${model.name} on $url" >&2
        : >"$log"
        llama-server \
          --model "$file" \
          --alias ${model.id} \
          --host 127.0.0.1 \
          --port ${toString model.port} \
          --ctx-size ${toString model.contextWindow} \
          --cache-type-k q8_0 \
          --cache-type-v q8_0 \
          --flash-attn on \
          --fit on \
          --jinja \
          --no-webui \
          >>"$log" 2>&1 &
        server=$!
        ready=""
        for _ in $(seq 1 600); do
          if ! kill -0 "$server" 2>/dev/null; then
            break
          fi
          if curl -fsS "$url/health" >/dev/null 2>&1; then
            ready=1
            break
          fi
          sleep 1
        done
        if [ -z "$ready" ]; then
          echo "omp-ablit: llama-server did not come up on $url:" >&2
          tail -n 20 "$log" >&2 || true
          exit 1
        fi
        vram
      fi

      omp --model ablit/${model.id} --config ${model.overlay} "$@"
    '';
  };
in {
  user.persist.directories = [model.dir];

  environment.systemPackages = [omp-ablit];
}
