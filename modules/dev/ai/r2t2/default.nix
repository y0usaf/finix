# Confucius4-R2T2 streaming ASR server: a resident GPU service (vLLM 0.14.0
# backend) on a WebSocket, replacing today's hand-started sandbox process
# (/home/y0usaf/dev/sandbox/r2t2-20260918). That README is the specification
# of what works; this module is the declaration that reproduces it.
#
# Pieces and where they land:
#   * ws_server.py - fetched from upstream at the pinned git rev and patched
#     with ws_server-memory-knobs.patch (upstream hardcodes
#     gpu_memory_utilization=0.95; on this shared 4090 that aborts at startup).
#     The patch stays a visible file next to this module, not a rewrite.
#   * Weights + VAD - pkgs.fetchurl, hash-pinned, assembled into one store
#     directory (house idiom: bolo.nix's models attrset). 3.9 GiB in the store
#     is a real cost, but it is the only form that survives a reboot with no
#     manual download.
#   * Python env - a uv venv in stateDir, materialised once by the declared
#     `r2t2-install` script. vLLM + torch cu128 as a pure nix package is a
#     large lift and PyPI wheels still need the LD_LIBRARY_PATH/TRITON hacks
#     below, so nix-packaging loses on cost; a service start step that rebuilds
#     the venv every boot loses on boot time and network dependence. A named
#     install step is the least-code genuinely reproducible option.
#   * Supervisor - finit.service (the house pattern for resident daemons:
#     paseo, ssh-agent, pipewire), NOT tomoe.process.service (compositor-scoped,
#     dies with the session; this server must outlive it).
#
# Inert until user.dev.r2t2.enable is set. Nothing here touches another
# module's behaviour.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.dev.r2t2;
  home = config.user.homeDirectory;
  user = config.user.name;
  # Desktop y0usaf's primary group is `users` (there is no y0usaf group), the
  # same fact paseo's service records; finit cannot fork the daemon otherwise.
  group =
    if cfg.group != null
    then cfg.group
    else "users";

  # --- source ---------------------------------------------------------------
  # Upstream repo at the clone's commit. NB: the Hugging Face revision
  # (185ce639...) is a weights revision, not the git commit; the server code
  # lives at 80c22e61... (both are pinned below).
  src = pkgs.fetchgit {
    url = "https://github.com/netease-youdao/Confucius4-R2T2";
    rev = "80c22e6140bcb9166fb9906798894fc8b18c8309";
    hash = "sha256-J965AYB3eh+FD4c790QiyDnaFT3TccW0bYXHGO7AeH4=";
    fetchLFS = false;
    fetchSubmodules = false;
  };

  # The carried local patch (feasibility-gate memory knobs). Applied to the
  # upstream tree so the change is reviewable as a diff in this directory.
  patched = pkgs.applyPatches {
    name = "Confucius4-R2T2-patched";
    inherit src;
    patches = [./ws_server-memory-knobs.patch];
  };

  # --- model files ----------------------------------------------------------
  hfRev = "185ce639118ad1362d049ca0d8ed04b6ec5cd6c9";
  hfBase = "https://huggingface.co/netease-youdao/Confucius4-R2T2/resolve/${hfRev}";
  hfFile = name: hash:
    pkgs.fetchurl {
      url = "${hfBase}/${name}";
      inherit hash;
    };

  # The full snapshot the server/vLLM reads from: config + tokenizer + the
  # 3.9 GiB bf16 weights (model.safetensors, 4076191640 bytes).
  weights = pkgs.linkFarm "Confucius4-R2T2-weights-${hfRev}" [
    {
      name = "config.json";
      path = hfFile "config.json" "sha256-gps7nOoIWkZFk1Ngl3SwjkiYkkJTrm1iPCtM2FU4ayM=";
    }
    {
      name = "generation_config.json";
      path = hfFile "generation_config.json" "sha256-HaUngk2B4HEY+s/0N+A/LiSiMxHjvesjaJc/535fJ1w=";
    }
    {
      name = "tokenizer.json";
      path = hfFile "tokenizer.json" "sha256-BJlgJxQWBGfy1ouRBlHWIWAgaJ8eAWvoei0AGe47rqs=";
    }
    {
      name = "tokenizer_config.json";
      path = hfFile "tokenizer_config.json" "sha256-SULQBWBCZoCTCcq8n06cuJzoVdWbFGgf3A4cxi6ibEw=";
    }
    {
      name = "vocab.json";
      path = hfFile "vocab.json" "sha256-yhDX6fs+0YV13R4neiV5wW0QjjLydDloSvoOELFECRA=";
    }
    {
      name = "merges.txt";
      path = hfFile "merges.txt" "sha256-iDHk8aBERxNA98CoPXvXEwaluGfpX9hw900MUwipBNU=";
    }
    {
      name = "added_tokens.json";
      path = hfFile "added_tokens.json" "sha256-3kB4RnfL0YQ8q+X77geMfgQs0LYhVfCBCvWhOELlcio=";
    }
    {
      name = "chat_template.json";
      path = hfFile "chat_template.json" "sha256-dajPyiTwDecteW+/7WhY/JYU7z2r2GlmhMw7wDqcWP8=";
    }
    {
      name = "preprocessor_config.json";
      path = hfFile "preprocessor_config.json" "sha256-ReEgpO2iwgxdfy6pNU5jU2vzXieqVz+3zfeAF7N4dw0=";
    }
    {
      name = "special_tokens_map.json";
      path = hfFile "special_tokens_map.json" "sha256-ezdsUQzPnYi7m77kHfxQUhIuFuDewRJKjYmDxZJZqfM=";
    }
    {
      name = "model.safetensors";
      path = hfFile "model.safetensors" "sha256-zE1TJNOGyA+YqKewn7zcyBOtCKZQP+OlhuuxROxGENw=";
    }
  ];

  # The VAD is unconditional in ws_server.py: a service without it is broken.
  # FireRedTeam/FireRedVAD Stream-VAD, at the revision the sandbox copied.
  vadRev = "7990aaccc6b7aec1e527743bd30201f2c4a03b8c";
  vadBase = "https://huggingface.co/FireRedTeam/FireRedVAD/resolve/${vadRev}/Stream-VAD";
  vad = pkgs.linkFarm "FireRedVAD-Stream-VAD-${vadRev}" [
    {
      name = "cmvn.ark";
      path = pkgs.fetchurl {
        url = "${vadBase}/cmvn.ark";
        hash = "sha256-yH9vE+3w8Ox1Nd38nMM4fZJoyyNLcBgtVmxeLt88pHM=";
      };
    }
    {
      name = "model.pth.tar";
      path = pkgs.fetchurl {
        url = "${vadBase}/model.pth.tar";
        hash = "sha256-7IiororF8ATNvSDB6sSp6dEgZ8PVGsWxQa+h+SH7Wck=";
      };
    }
  ];

  python = pkgs.python312;
  inherit (pkgs) uv;

  # --- NixOS runtime environment -------------------------------------------
  # PyPI wheels (numpy, torch, vllm) need sonames NixOS does not put on the
  # default search path. Without libz numpy fails to import; without libstdc++
  # torch/vllm fail. TRITON_LIBCUDA_PATH replaces the /sbin/ldconfig lookup
  # triton does (NixOS has none). The ptxas/cuobjdump/nvdisasm bundled in the
  # triton wheel are non-executable here, so point triton at the store CUDA
  # 12.9 toolchain (matches the sandbox env.sh). See the sandbox README for the
  # crash each of these prevents.
  cuda = pkgs.cudaPackages;
  # /run/opengl-driver/lib is a directory of .so files, not a package prefix:
  # lib.makeLibraryPath would append "/lib" to it (the sandbox env.sh puts the
  # bare directory on LD_LIBRARY_PATH). cc.cc.lib + zlib ARE package prefixes.
  ldLibraryPath = lib.concatStringsSep ":" [
    "/run/opengl-driver/lib"
    "${pkgs.stdenv.cc.cc.lib}/lib"
    "${pkgs.zlib}/lib"
  ];
  runtimeEnv = {
    LD_LIBRARY_PATH = ldLibraryPath;
    TRITON_LIBCUDA_PATH = "/run/opengl-driver/lib";
    TRITON_PTXAS_PATH = "${cuda.cuda_nvcc}/bin/ptxas";
    TRITON_CUOBJDUMP_PATH = "${cuda.cuda_cuobjdump}/bin/cuobjdump";
    TRITON_NVDISASM_PATH = "${cuda.cuda_nvdisasm}/bin/nvdisasm";
    PYTORCH_CUDA_ALLOC_CONF = "expandable_segments:True";
    # vLLM spawns its engine worker; fork-in-CUDA is unsafe.
    VLLM_WORKER_MULTIPROC_METHOD = "spawn";
    # Triton JIT-builds a small kernel during vLLM engine init and looks up a C
    # compiler by name: with no cc/gcc on the service PATH it dies with
    # "RuntimeError: Failed to find C compiler" and finit respawn-loops the
    # server. Point it at the store gcc wrapper explicitly.
    CC = "${pkgs.stdenv.cc}/bin/cc";
  };

  # --- paths ----------------------------------------------------------------
  envDir = "${cfg.stateDir}/.venv";
  runDir = "${cfg.stateDir}/run";
  logDir = "${cfg.stateDir}/logs";

  # Finit notify:systemd readiness signalling helper. Standalone so the service
  # wrapper need not embed a heredoc.
  notifyScript = pkgs.writeText "r2t2-notify-ready.py" ''
    import os, socket
    addr = os.environ.get("NOTIFY_SOCKET")
    if not addr:
        raise SystemExit(0)
    if addr[0] == "@":
        addr = "\0" + addr[1:]
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    try:
        sock.connect(addr)
        sock.send(b"READY=1")
    except OSError:
        pass
    finally:
        sock.close()
  '';

  # The pin set from the sandbox install.sh. vllm is pinned by qwen-asr[vllm];
  # the other two vllm venvs on this box (0.28.0 / 0.29.0) carry transformers
  # 5.x and are incompatible - do not reuse them.
  installScript = pkgs.writeShellScriptBin cfg.installEnvPackageName ''
    set -euo pipefail
    mkdir -p ${lib.escapeShellArg cfg.stateDir}
    export PATH=${lib.makeBinPath [uv python pkgs.coreutils]}

    echo "r2t2-install: creating venv at ${envDir}"
    uv venv --python ${python}/bin/python3.12 ${envDir}

    uv pip install --python ${envDir}/bin/python \
      "vllm==0.14.0" "transformers==4.57.6" \
      librosa soundfile sanic fireredvad websockets
    uv pip install --python ${envDir}/bin/python --no-deps "qwen-asr==0.0.6"
    uv pip install --python ${envDir}/bin/python \
      nagisa soynlp accelerate qwen-omni-utils

    echo "r2t2-install: venv ready at ${envDir}"
    echo "r2t2-install: the repo (r2t2 import) is provided via PYTHONPATH=${patched}; not installed into the venv."
  '';
in {
  options.user.dev.r2t2 = {
    enable = lib.mkEnableOption "Confucius4-R2T2 streaming ASR server (resident vLLM WebSocket service)";

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address the server binds. Loopback by default (the sandbox binds 127.0.0.1).";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8272;
      description = "WebSocket port. WS URI is ws://<listenAddress>:<port>/asr_stream_api_v1.";
    };

    gpuMemoryUtilization = lib.mkOption {
      type = lib.types.float;
      default = 0.20;
      description = ''
        vLLM gpu_memory_utilization (fraction of total VRAM). Defaults to the
        measured working point (~4.75 GiB of 24 GiB): upstream's hardcoded 0.95
        aborts on this shared GPU. Requires the applied patch.
      '';
    };

    maxModelLen = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4096;
      description = "ASR_MAX_MODEL_LEN: vLLM max_model_len.";
    };

    maxNumBatchedTokens = lib.mkOption {
      type = lib.types.ints.positive;
      default = 256;
      description = ''
        ASR_MAX_NUM_BATCHED_TOKENS (implies max_num_seqs=1). 256 is the
        measured working point for the streaming single-request workload.
      '';
    };

    enforceEager = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "ASR_ENFORCE_EAGER: skip CUDA graphs (needed to fit the memory budget).";
    };

    skipMmProfiling = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        ASR_SKIP_MM_PROFILING: skip the multimodal-encoder profiling run,
        which OOMs at this free-memory level.
      '';
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "${home}/.local/share/r2t2";
      description = ''
        Durable directory holding the uv venv, run directory, and logs. On a
        homeReset host this MUST be an allowlisted path or it is wiped on
        reboot; the module registers it under finix.persistence.allowlist
        (a no-op on hosts without finix's persistence module).
      '';
    };

    group = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Group the daemon runs as. Default: `users`, the primary group finit
        needs on this fleet (there is no same-named user group).
      '';
    };

    installEnvPackageName = lib.mkOption {
      type = lib.types.str;
      default = "r2t2-install";
      description = "Name of the venv installer script placed on PATH when enabled.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Extra environment variables for the daemon (merged over the module defaults).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.gpuMemoryUtilization > 0.0 && cfg.gpuMemoryUtilization <= 1.0;
        message = "user.dev.r2t2.gpuMemoryUtilization must be in (0, 1].";
      }
    ];

    # The installer script is the declared, one-time environment step.
    environment.systemPackages = [installScript];

    # Durability: the state dir must survive the homeReset rotation. Merging
    # into the existing allowlist leaves every other entry alone. Only
    # reachable when this host also imports finix's persistence module; the
    # module is inert otherwise, so no other host is perturbed.
    finix.persistence.allowlist.users."${user}".directories = [
      (lib.removePrefix "${home}/" cfg.stateDir)
    ];

    finit.services.r2t2 = {
      description = "Confucius4-R2T2 streaming ASR server (vLLM, WebSocket)";
      inherit user group;

      environment =
        {
          HOME = home;
          PYTHONPATH = "${patched}";
          ASR_MODEL_PATH = "${weights}";
          VAD_MODEL_PATH = "${vad}";
          ASR_GPU_MEMORY_UTILIZATION = toString cfg.gpuMemoryUtilization;
          ASR_MAX_MODEL_LEN = toString cfg.maxModelLen;
          ASR_MAX_NUM_BATCHED_TOKENS = toString cfg.maxNumBatchedTokens;
          ASR_ENFORCE_EAGER = lib.optionalString cfg.enforceEager "1";
          ASR_SKIP_MM_PROFILING = lib.optionalString cfg.skipMmProfiling "1";
        }
        // runtimeEnv
        // cfg.environment;

      path = [pkgs.coreutils pkgs.gnugrep pkgs.stdenv.cc];

      # Supervise the server directly; restart whenever it leaves (crash or
      # clean exit - it is never supposed to exit on its own). respawn keeps
      # restarting without counting toward the retry limit, matching bolod's
      # restart="on_exit" reading in bolo.nix.
      respawn = true;

      # finit-native readiness: the wrapper starts the server, waits for the
      # socket to accept a connection, then signals READY=1 to $NOTIFY_SOCKET.
      # Dependents can gate on `service/r2t2/ready`. See the runbook.
      notify = "systemd";

      command = pkgs.writeShellScript "r2t2-server" ''
        set -eu
        export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gnugrep python pkgs.stdenv.cc]}

        run=${lib.escapeShellArg runDir}
        mkdir -p "$run" ${lib.escapeShellArg logDir}
        # ws_server.py makes its logs/ and wav_tmp_store/ dirs relative to
        # dirname(__file__) at import time (and per request). A store path is
        # read-only, so run from a writable copy: __file__ must resolve here.
        install -m 0644 ${patched}/ws_server.py "$run/ws_server.py"
        mkdir -p "$run/logs/requests" "$run/wav_tmp_store"

        # The venv is a declared, one-time install step (r2t2-install); it is
        # NOT built here. Wait for it rather than crash-looping (house idiom:
        # the runtime-dir / pipewire-socket waits in desktop/user-daemons.nix
        # and desktop/audio.nix). finit re-runs us if the budget runs out.
        mypy=${envDir}/bin/python
        for _ in $(seq 1 600); do
          [ -x "$mypy" ] && break
          sleep 1
        done
        if [ ! -x "$mypy" ]; then
          echo "r2t2: venv missing at ${envDir}; run ${installScript}/bin/${cfg.installEnvPackageName} first" >&2
          exit 1
        fi

        cd "$run"
        "$mypy" -u "$run/ws_server.py" \
          --ip ${lib.escapeShellArg cfg.listenAddress} \
          --port ${toString cfg.port} \
          --asr_model_path ${lib.escapeShellArg (toString weights)} \
          --vad_model_path ${lib.escapeShellArg (toString vad)} &
        server_pid=$!

        # Forward stop/term so finit's SIGTERM tears the server down.
        trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

        # Wait for the socket, then declare readiness to finit (notify:systemd).
        ready=0
        for _ in $(seq 1 300); do
          if ! kill -0 "$server_pid" 2>/dev/null; then
            wait "$server_pid"
            exit $?
          fi
          if ${pkgs.netcat}/bin/nc -z ${lib.escapeShellArg cfg.listenAddress} ${toString cfg.port} 2>/dev/null; then
            ready=1
            break
          fi
          sleep 1
        done
        if [ "$ready" = 1 ] && [ -n "''${NOTIFY_SOCKET:-}" ]; then
          "$mypy" ${notifyScript} || true
        fi

        wait "$server_pid"
      '';

      log = true;
      conditions = ["net/lo/up"];
    };
  };
}
