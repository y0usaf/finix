{
  config,
  lib,
  pkgs,
  ...
}: let
  baseDir = ".local/share/omp-ablit";
  model = let
    file = "Huihui-Qwen3.8-27B-abliterated-UD-DW-Q4_K_M.gguf";
  in {
    port = 8090;
    id = "qwen3.8-27b-abliterated";
    name = "Qwen 3.8 27B Abliterated (local)";
    dir = baseDir;
    inherit file;
    url = "https://huggingface.co/huihui-ai/Huihui-Qwen3.8-27B-abliterated-GGUF/resolve/main/${file}";
    sha256 = "0c7cfe3060493485bb9a6a51195897b0c1d347a49929206adb9a52170183ea03";
    contextWindow = 131072;
    maxTokens = 16384;
    program = "/mnt/seed/current/bin/omp-ablit";
  };
  inkling = {
    port = 8091;
    id = "inkling-2-mini-abliterated";
    name = "Inkling 2 Mini Abliterated (local)";
    dir = baseDir;
    subdir = "Inkling-2-Mini-ingine";
    contextWindow = 65536;
    maxTokens = 16384;
    program = "/mnt/seed/current/bin/omp-ablit-inkling";
    repoBase = "https://huggingface.co/satellitedown/Inkling-2-Mini-abliterated-ingine/resolve/6e823ba00310";
    minFreeVramMiB = 18500;
    files = [
      {
        path = "chat_template.jinja";
        sha256 = "53a9035f3255945704b5857657cfb00c1165090c0641c4f782a0cbf268cc16dc";
      }
      {
        path = "config.json";
        sha256 = "8216dd43157f5474cfff88f486a1e433fef703c674f694e485a86a761c412b1e";
      }
      {
        path = "generation_config.json";
        sha256 = "a08737c07a65a8fdf69f7cf086576210e5aad4b241437090b26d7b0c4f7905f7";
      }
      {
        path = "hf_quant_config.json";
        sha256 = "7c656207d3ce37879c7be209a036b0dde43bf01f78159bff06880b868ed57143";
      }
      {
        path = "inkling-2-mini-abliterated.safetensors";
        sha256 = "9467240bdbcd4737a3496bf167525989d79196dbeec582361880ad4d8cbe4d73";
      }
      {
        path = "model-00001-of-00001.safetensors";
        sha256 = "65e60f51aa1284d4fb022584908c315270334d991828bb774af60584523539d1";
      }
      {
        path = "model.safetensors.index.json";
        sha256 = "c1631065b7b00787993522dddc66a68b3abee869192977fb3dcb796e63bc5838";
      }
      {
        path = "mtp.safetensors";
        sha256 = "7c3b651317f01f73bcf4e1dceba66ef8b7e1a1eac6bc171e882e690a4b10a1d2";
      }
      {
        path = "processor_config.json";
        sha256 = "d7350adce18c8be4b607f261c8f0f7eabbf720bb7aaf648a43d4f8372bbacc2d";
      }
      {
        path = "special_tokens_map.json";
        sha256 = "c16f44b3594563d82743ddb0417a2be1bfe3e2000dfad2da4b8f32554593e1a0";
      }
      {
        path = "tiktoken/tokenizer.model";
        sha256 = "f170372dd655728909228220d77cf6b8104a59f38a91262a7d2c4027906ec0d8";
      }
      {
        path = "tokenizer.json";
        sha256 = "7f332727f9a3f093dd452a39cc978e6757627e5dad1b0673aa4e75174f236dd6";
      }
      {
        path = "tokenizer_config.json";
        sha256 = "bf09342d285139fd37ce10c70878af1d52cb390e9901e10248654293a80ee636";
      }
    ];
  };
  home = config.user.homeDirectory;
  dir = "${home}/${model.dir}";
  url = "http://127.0.0.1:${toString model.port}";
  inklingUrl = "http://127.0.0.1:${toString inkling.port}";
  inkling-ingine = import ../../../../pkgs/inkling-ingine.nix {inherit pkgs;};
  omp-ablit-qwen = pkgs.writeShellApplication {
    name = "omp-ablit-qwen";
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
  inklingFetchLines =
    lib.concatMapStringsSep "\n" (f: ''
      fetch_file ${lib.escapeShellArg f.path} ${lib.escapeShellArg f.sha256}
    '')
    inkling.files;
  omp-ablit-inkling = pkgs.writeShellApplication {
    name = "omp-ablit-inkling";
    runtimeInputs = [pkgs.coreutils pkgs.curl inkling-ingine];
    text = ''
      model_dir=${dir}/${inkling.subdir}
      url=${inklingUrl}

      fetch_file() {
        rel=$1
        expected=$2
        dest="$model_dir/$rel"
        if [ -f "$dest" ]; then
          return 0
        fi
        mkdir -p "$(dirname "$dest")"
        echo "omp-ablit-inkling: fetching $rel into $model_dir" >&2
        curl -fL --retry 5 -o "$dest.part" "${inkling.repoBase}/$rel"
        echo "$expected  $dest.part" | sha256sum -c -
        mv "$dest.part" "$dest"
      }

      ${inklingFetchLines}

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
        echo "omp-ablit-inkling: using the ingine-serve another session already runs on $url" >&2
      else
        if command -v nvidia-smi >/dev/null 2>&1; then
          vram=$(nvidia-smi --query-gpu=memory.free,memory.total --format=csv,noheader,nounits | head -n1)
          free_mib=$(printf '%s' "$vram" | cut -d',' -f1 | tr -d ' ')
          total_mib=$(printf '%s' "$vram" | cut -d',' -f2 | tr -d ' ')
          if [ -n "$free_mib" ] && [ "$free_mib" -lt ${toString inkling.minFreeVramMiB} ]; then
            echo "omp-ablit-inkling: insufficient free VRAM ($free_mib / $total_mib MiB free; need >= ${toString inkling.minFreeVramMiB} MiB)" >&2
            exit 1
          fi
        fi

        echo "omp-ablit-inkling: starting ${inkling.name} on $url" >&2
        before=$(mem || true)
        ingine-serve \
          --engine \
          --model-dir "$model_dir" \
          --ablation "$model_dir/inkling-2-mini-abliterated.safetensors" \
          --model-id ${inkling.id} \
          --host 127.0.0.1 \
          --port ${toString inkling.port} \
          --max-ctx ${toString inkling.contextWindow} \
          --dense-fp8 \
          --kv-fp8 \
          --offload-experts 4 \
          --spec \
          --spec-threshold 0.8 \
          --no-vision \
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
          echo "omp-ablit-inkling: ingine-serve did not come up on $url" >&2
          exit 1
        fi
        echo "omp-ablit-inkling: VRAM used,total after the load: $(mem || echo unknown) MiB; before it: $before" >&2
      fi

      OMP_BOX_PROGRAM=${inkling.program} omp-box "$@"
    '';
  };
  omp-ablit =
    if config.hardware.nvidia.enable
    then
      pkgs.writeShellScriptBin "omp-ablit" ''
        exec ${omp-ablit-inkling}/bin/omp-ablit-inkling "$@"
      ''
    else
      pkgs.writeShellScriptBin "omp-ablit" ''
        exec ${omp-ablit-qwen}/bin/omp-ablit-qwen "$@"
      '';
in {
  _module.args.ablit = model // {inherit inkling;};
  user.persist.directories = [model.dir];

  environment.systemPackages = [omp-ablit omp-ablit-qwen] ++ lib.optionals config.hardware.nvidia.enable [inkling-ingine omp-ablit-inkling];
}
