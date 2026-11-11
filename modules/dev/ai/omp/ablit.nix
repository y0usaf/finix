{
  config,
  lib,
  pkgs,
  ...
}: let
  # The local refusal-removed model omp-ablit serves, set once here for its server and, as the ablit module argument, omp's provider
  # (box.nix). huihui-ai's abliterated Qwen 3.8 27B, chosen by y0usaf; the UGI Leaderboard has not scored any
  # Qwen 3.8 yet. The Unsloth-dynamic Q4_K_M quant (15.4 GiB) with a q4_0 KV cache of a 131072-token window, one slot, fits
  # beside bolod and the desktop; llama.cpp's --fit spills layers to the CPU when another job holds the card, so a
  # busy GPU costs speed, not a failed start. Qwen 3.8 calls tools natively.
  model = let
    file = "Huihui-Qwen3.8-27B-abliterated-UD-DW-Q4_K_M.gguf";
  in {
    port = 8090;
    id = "qwen3.8-27b-abliterated";
    name = "Qwen 3.8 27B Abliterated (local)";
    dir = ".local/share/omp-ablit";
    inherit file;
    url = "https://huggingface.co/huihui-ai/Huihui-Qwen3.8-27B-abliterated-GGUF/resolve/main/${file}";
    sha256 = "0c7cfe3060493485bb9a6a51195897b0c1d347a49929206adb9a52170183ea03";
    contextWindow = 131072;
    maxTokens = 16384;
    # omp-ablit's box half, placed in the box seed by box.nix: omp runs in the box, which sees only the paths its
    # shares carry, so the program rides the seed share like the config omp already reads there.
    program = "/mnt/seed/current/bin/omp-ablit";
  };
  home = config.user.homeDirectory;
  dir = "${home}/${model.dir}";
  url = "http://127.0.0.1:${toString model.port}";
  # Serves the model omp-ablit picked (model above) from the 4090 for as long as one omp run lasts. The box's
  # QEMU user networking hands omp, which runs in the box, the host loopback as 10.0.2.2, so the box's provider
  # entry (box.nix) reaches this server and the LAN never does. --fit offloads as few layers to the CPU as the
  # free VRAM of the moment allows, so a running GPU job costs speed, not a failed start.
  omp-ablit = pkgs.writeShellApplication {
    name = "omp-ablit";
    runtimeInputs = [pkgs.coreutils pkgs.curl pkgs.llama-cpp];
    text = ''
      dir=${dir}
      file="$dir/${model.file}"
      url=${url}

      mkdir -p "$dir"
      if [ ! -f "$file" ]; then
        echo "omp-ablit: fetching ${model.file} into $dir, once" >&2
        curl -fL --retry 5 -o "$file.part" ${model.url}
        echo "${model.sha256}  $file.part" | sha256sum -c -
        mv "$file.part" "$file"
      fi

      server=""
      mem() {
        command -v nvidia-smi >/dev/null 2>&1 || return 0
        nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits
      }
      cleanup() {
        status=$?
        trap - EXIT
        if [ -n "$server" ]; then
          kill "$server" 2>/dev/null || true
          wait "$server" 2>/dev/null || true
        fi
        exit "$status"
      }
      trap cleanup EXIT

      if curl -fsS "$url/health" >/dev/null 2>&1; then
        echo "omp-ablit: using the llama-server another session already runs on $url" >&2
      else
        echo "omp-ablit: starting ${model.name} on $url" >&2
        before=$(mem || true)
        llama-server \
          --model "$file" \
          --alias ${model.id} \
          --host 127.0.0.1 \
          --port ${toString model.port} \
          --ctx-size ${toString model.contextWindow} \
          --cache-type-k q4_0 \
          --cache-type-v q4_0 \
          --parallel 1 \
          --flash-attn on \
          --fit on \
          --jinja \
          --no-webui \
          >/dev/null 2>&1 &
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
          echo "omp-ablit: llama-server did not come up on $url" >&2
          exit 1
        fi
        echo "omp-ablit: VRAM used,total after the load: $(mem || echo unknown) MiB; before it: $before" >&2
      fi

      OMP_BOX_PROGRAM=${model.program} omp-box "$@"
    '';
  };
in {
  _module.args.ablit = model;
  user.persist.directories = [model.dir];

  environment.systemPackages = [omp-ablit];
}
