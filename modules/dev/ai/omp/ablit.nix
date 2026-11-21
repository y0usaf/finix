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
    cacheType = "q4_0";
    minFreeVramMiB = 17500;
    program = "/mnt/seed/current/bin/omp-ablit";
  };
  gemma = let
    file = "gemma-4-26b-a4b-heretic-styletune-v2-head.Q4_K_M.gguf";
  in {
    port = 8090;
    id = "gemma-4-26b-a4b-heretic-styletune-v2";
    name = "Gemma 4 26B A4B Heretic StyleTune v2 (local)";
    dir = baseDir;
    inherit file;
    url = "https://huggingface.co/mradermacher/gemma-4-26b-a4b-heretic-styletune-v2-head-GGUF/resolve/9f025187e9d7f38d14d8e9d6d23696f739039089/${file}";
    sha256 = "f7fa244106a83dea988e3a66428f3c17e3a3f967b030ab05c450f605b87e713c";
    contextWindow = 65536;
    maxTokens = 16384;
    cacheType = "q8_0";
    minFreeVramMiB = 17500;
    program = "/mnt/seed/current/bin/omp-ablit-gemma";
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
  inklingUrl = "http://127.0.0.1:${toString inkling.port}";
  inkling-ingine = import ../../../../pkgs/inkling-ingine.nix {inherit pkgs;};

  ephemeralTernPrelude = ''
    if [ -n "''${TERN_PANE:-}" ] && [ -z "''${OMP_ABLIT_EPHEMERAL_TERM:-}" ] && [ -z "''${OMP_ABLIT_INLINE:-}" ] && [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -t 0 ] && [ -t 1 ] && command -v tern >/dev/null 2>&1; then
      ephemeral=$(mktemp -d "''${XDG_RUNTIME_DIR:-/tmp}/omp-ablit-term.XXXXXX")
      chmod 700 "$ephemeral"
      dpid=""
      cleanup_tern() {
        status=''${1:-$?}
        trap - EXIT HUP INT TERM
        if [ -n "$dpid" ]; then
          kill "$dpid" 2>/dev/null || true
          wait "$dpid" 2>/dev/null || true
        fi
        rm -rf "$ephemeral"
        exit "$status"
      }
      trap cleanup_tern EXIT
      trap 'cleanup_tern 129' HUP
      trap 'cleanup_tern 130' INT
      trap 'cleanup_tern 143' TERM
      mkdir -p "$ephemeral/cfg" "$ephemeral/state" "$ephemeral/cache"
      if [ -f "$HOME/.config/tern/settings.json" ]; then
        jq '.scrollback_lines = 0' "$HOME/.config/tern/settings.json" > "$ephemeral/cfg/settings.json" 2>/dev/null || cp "$HOME/.config/tern/settings.json" "$ephemeral/cfg/settings.json"
      else
        printf '{"scrollback_lines":0}\n' > "$ephemeral/cfg/settings.json"
      fi
      env -u TERN_PANE -u TERN_WINDOW_KEY \
        TERN_CONFIG_DIR="$ephemeral/cfg" \
        TERN_DAEMON_SOCKET="$ephemeral/tern.sock" \
        XDG_STATE_HOME="$ephemeral/state" \
        XDG_CACHE_HOME="$ephemeral/cache" \
        tern daemon --socket "$ephemeral/tern.sock" >/dev/null 2>&1 &
      dpid=$!
      for _ in $(seq 1 50); do
        [ -S "$ephemeral/tern.sock" ] && break
        sleep 0.1
      done
      rc=0
      env -u TERN_PANE -u TERN_WINDOW_KEY \
        OMP_ABLIT_EPHEMERAL_TERM=1 \
        TERN_CONFIG_DIR="$ephemeral/cfg" \
        TERN_DAEMON_SOCKET="$ephemeral/tern.sock" \
        XDG_STATE_HOME="$ephemeral/state" \
        XDG_CACHE_HOME="$ephemeral/cache" \
        tern -e "$0" "$@" || rc=$?
      cleanup_tern "$rc"
    fi
  '';

  mkLlamaLauncher = {
    binName,
    spec,
  }:
    pkgs.writeShellApplication {
      name = binName;
      runtimeInputs = [pkgs.coreutils pkgs.curl pkgs.jq pkgs.llama-cpp];
      text = ''
        ${ephemeralTernPrelude}
        dir=${dir}
        file="$dir/${spec.file}"
        url="http://127.0.0.1:${toString spec.port}"

        mkdir -p "$dir"
        if [ ! -f "$file" ]; then
          echo "${binName}: fetching ${spec.file} into $dir, once" >&2
          curl -fL --retry 5 -o "$file.part" ${lib.escapeShellArg spec.url}
          echo "${spec.sha256}  $file.part" | sha256sum -c -
          mv "$file.part" "$file"
        fi

        server=""
        mem() {
          command -v nvidia-smi >/dev/null 2>&1 || return 0
          nvidia-smi --query-gpu=memory.used,memory.free,memory.total --format=csv,noheader,nounits | head -n1
        }
        cleanup() {
          status=$?
          trap - EXIT HUP INT TERM
          if [ -n "$server" ]; then
            kill "$server" 2>/dev/null || true
            for _ in $(seq 1 25); do
              kill -0 "$server" 2>/dev/null || break
              sleep 0.2
            done
            kill -9 "$server" 2>/dev/null || true
            wait "$server" 2>/dev/null || true
          fi
          exit "$status"
        }
        trap cleanup EXIT
        trap 'exit 129' HUP
        trap 'exit 130' INT
        trap 'exit 143' TERM

        if curl -fsS "$url/health" >/dev/null 2>&1; then
          loaded=$(curl -fsS "$url/v1/models" 2>/dev/null | jq -r '.data[0].id // empty' || true)
          if [ "$loaded" != ${lib.escapeShellArg spec.id} ]; then
            echo "${binName}: $url is already serving '$loaded' (requested '${spec.id}'); stop that session first" >&2
            exit 1
          fi
          echo "${binName}: using the llama-server already running ${spec.id} on $url" >&2
        else
          if command -v nvidia-smi >/dev/null 2>&1; then
            vram=$(nvidia-smi --query-gpu=memory.free,memory.total --format=csv,noheader,nounits | head -n1)
            free_mib=$(printf '%s' "$vram" | cut -d',' -f1 | tr -d ' ')
            total_mib=$(printf '%s' "$vram" | cut -d',' -f2 | tr -d ' ')
            if [ -n "$free_mib" ] && [ "$free_mib" -lt ${toString spec.minFreeVramMiB} ]; then
              echo "${binName}: insufficient free VRAM ($free_mib / $total_mib MiB free; need >= ${toString spec.minFreeVramMiB} MiB)" >&2
              exit 1
            fi
          fi

          echo "${binName}: starting ${spec.name} on $url" >&2
          before=$(mem || true)
          llama-server \
            --model "$file" \
            --alias ${lib.escapeShellArg spec.id} \
            --host 127.0.0.1 \
            --port ${toString spec.port} \
            --ctx-size ${toString spec.contextWindow} \
            --cache-type-k ${spec.cacheType} \
            --cache-type-v ${spec.cacheType} \
            --parallel 1 \
            --flash-attn on \
            --fit on \
            --fit-target 5120 \
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
            echo "${binName}: llama-server did not come up on $url" >&2
            exit 1
          fi
          echo "${binName}: VRAM used,free,total after load: $(mem || echo unknown) MiB (before: $before)" >&2
        fi

        prompt_file="${dir}/system.md"
        prompt=""
        if [ -f "$prompt_file" ]; then
          prompt=$(cat "$prompt_file")
        fi
        set -- --ablit-system-prompt "$prompt" "$@"
        OMP_BOX_PROGRAM=${spec.program} omp-box "$@"
      '';
    };

  omp-ablit-qwen = mkLlamaLauncher {
    binName = "omp-ablit-qwen";
    spec = model;
  };
  omp-ablit-gemma = mkLlamaLauncher {
    binName = "omp-ablit-gemma";
    spec = gemma;
  };
  inklingFetchLines =
    lib.concatMapStringsSep "\n" (f: ''
      fetch_file ${lib.escapeShellArg f.path} ${lib.escapeShellArg f.sha256}
    '')
    inkling.files;
  omp-ablit-inkling = pkgs.writeShellApplication {
    name = "omp-ablit-inkling";
    runtimeInputs = [pkgs.coreutils pkgs.curl pkgs.jq inkling-ingine];
    text = ''
      ${ephemeralTernPrelude}
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
        nvidia-smi --query-gpu=memory.used,memory.free,memory.total --format=csv,noheader,nounits | head -n1
      }
      cleanup() {
        status=$?
        trap - EXIT HUP INT TERM
        if [ -n "$server" ]; then
          kill "$server" 2>/dev/null || true
          for _ in $(seq 1 25); do
            kill -0 "$server" 2>/dev/null || break
            sleep 0.2
          done
          kill -9 "$server" 2>/dev/null || true
          wait "$server" 2>/dev/null || true
        fi
        exit "$status"
      }
      trap cleanup EXIT
      trap 'exit 129' HUP
      trap 'exit 130' INT
      trap 'exit 143' TERM

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
        echo "omp-ablit-inkling: VRAM used,free,total after load: $(mem || echo unknown) MiB (before: $before)" >&2
      fi

      prompt_file="${dir}/system.md"
      prompt=""
      if [ -f "$prompt_file" ]; then
        prompt=$(cat "$prompt_file")
      fi
      set -- --ablit-system-prompt "$prompt" "$@"
      OMP_BOX_PROGRAM=${inkling.program} omp-box "$@"
    '';
  };
  selector =
    if config.hardware.nvidia.enable
    then {
      defaultChoice = "inkling";
      runInkling = ''exec ${omp-ablit-inkling}/bin/omp-ablit-inkling "$@"'';
      menu = ''
        printf 'Select omp-ablit model:\n' >&2
        printf '  1) inkling  (Inkling 2 Mini Abliterated, 64K, ingine-serve)\n' >&2
        printf '  2) gemma    (Gemma 4 26B A4B Heretic + StyleTune v2 Q4_K_M, 64K, llama-server)\n' >&2
        printf '  3) qwen     (Qwen 3.8 27B Abliterated Q4_K_M, 128K, llama-server)\n' >&2
        printf 'Choice [1-3, default 1]: ' >&2
        IFS= read -r pick || exit 1
        case "''${pick:-1}" in
          1 | inkling) choice=inkling ;;
          2 | gemma) choice=gemma ;;
          3 | qwen) choice=qwen ;;
          *)
            echo "omp-ablit: invalid choice '$pick'" >&2
            exit 1
            ;;
        esac
      '';
    }
    else {
      defaultChoice = "gemma";
      runInkling = ''
        echo "omp-ablit: inkling requires NVIDIA CUDA" >&2
        exit 1
      '';
      menu = ''
        printf 'Select omp-ablit model:\n' >&2
        printf '  1) gemma    (Gemma 4 26B A4B Heretic + StyleTune v2 Q4_K_M, 64K, llama-server)\n' >&2
        printf '  2) qwen     (Qwen 3.8 27B Abliterated Q4_K_M, 128K, llama-server)\n' >&2
        printf 'Choice [1-2, default 1]: ' >&2
        IFS= read -r pick || exit 1
        case "''${pick:-1}" in
          1 | gemma) choice=gemma ;;
          2 | qwen) choice=qwen ;;
          *)
            echo "omp-ablit: invalid choice '$pick'" >&2
            exit 1
            ;;
        esac
      '';
    };
  omp-ablit = pkgs.writeShellApplication {
    name = "omp-ablit";
    runtimeInputs = [pkgs.coreutils pkgs.jq];
    text = ''
      ${ephemeralTernPrelude}
      choice=""
      case "''${1:-}" in
        inkling | gemma | qwen)
          choice=$1
          shift
          ;;
      esac

      if [ -z "$choice" ]; then
        if [ -t 0 ] && [ -t 1 ]; then
          ${selector.menu}
        else
          choice=${selector.defaultChoice}
        fi
      fi

      case "$choice" in
        inkling)
          ${selector.runInkling}
          ;;
        gemma)
          exec ${omp-ablit-gemma}/bin/omp-ablit-gemma "$@"
          ;;
        qwen)
          exec ${omp-ablit-qwen}/bin/omp-ablit-qwen "$@"
          ;;
      esac
    '';
  };
in {
  _module.args.ablit = model // {inherit gemma inkling;};
  user.persist.directories = [model.dir];

  environment.systemPackages =
    [omp-ablit omp-ablit-gemma omp-ablit-qwen]
    ++ lib.optionals config.hardware.nvidia.enable [inkling-ingine omp-ablit-inkling];
}
