# Confucius4-R2T2 streaming ASR server runbook

Declared by `modules/dev/ai/r2t2/default.nix` (`user.dev.r2t2`), enabled on
the desktop host in `modules/hosts/y0usaf-desktop/dev.nix`. It replaces the
hand-started feasibility process that lived at
`/home/y0usaf/dev/sandbox/r2t2-20260918`. That sandbox `README.md` remains
the authoritative description of the model, the message contract, and the
NixOS environment hazards; this file references it rather than duplicating it.

## What runs

- Backend: vLLM 0.14.0 (the repo pin via `qwen-asr[vllm]`). Streaming ASR is
  vLLM-only; the transformers backend raises for every streaming call.
- Repo: `github.com/netease-youdao/Confucius4-R2T2` at git commit
  `80c22e6140bcb9166fb9906798894fc8b18c8309`, with
  `ws_server-memory-knobs.patch` applied (see "The patch" below).
- Weights: `netease-youdao/Confucius4-R2T2`, HF revision
  `185ce639118ad1362d049ca0d8ed04b6ec5cd6c9` (`model.safetensors`
  4076191640 bytes, bfloat16), fetched by `pkgs.fetchurl` into the store.
  NB: the HF revision is a weights revision, not the git commit.
- VAD: `FireRedTeam/FireRedVAD` `Stream-VAD` at revision
  `7990aaccc6b7aec1e527743bd30201f2c4a03b8c`. The server runs the VAD
  unconditionally; a service without it is broken.
- Supervisor: a finit `service` running as `y0usaf:users`, `respawn = true`,
  `notify = "systemd"`. It restarts on crash and on clean exit.
- Port (default): 8272. WS URI: `ws://127.0.0.1:8272/asr_stream_api_v1`.

## Build and enable

    # Evaluate the module (inert by default):
    nix eval --impure --apply 'x: builtins.attrNames x' \
      .#nixosConfigurations.y0usaf-desktop.config.user.dev.r2t2

    # Full system build (does NOT activate): the enabled desktop toplevel.
    nix build .#nixosConfigurations.y0usaf-desktop.config.system.build.toplevel

    # Cheap whole-flake check:
    nix flake check

Activation is `nh os switch` / boot, deliberately out of scope here. Building
only proves the closure; enabling the module on the host makes the finit
service part of that closure.

## Python environment (the one manual step)

vLLM + torch cu128 as a pure nix package is a large lift, and PyPI wheels
still need the `LD_LIBRARY_PATH`/TRITON environment below, so the venv is
materialised once by a declared installer rather than rebuilt every boot:

    r2t2-install      # on PATH once the module is enabled

It runs the sandbox `install.sh` pin set into `${stateDir}/.venv`
(`~/.local/share/r2t2/.venv` by default). Re-run it after changing the pin
set. It is idempotent and uses the local `uv` cache, so on this box it
completes in about a second after the first time. The repo itself is on
`PYTHONPATH` (the `r2t2` import) from the patched store tree; it is not
pip-installed into the venv.

Durability: the desktop host has `finix.persistence.homeReset.enable = true`,
which rotates `@home` back to `@home-blank` on every boot. The module
therefore registers `stateDir` in
`finix.persistence.allowlist.users.y0usaf.directories`, so the venv survives a
reboot and no manual download is needed. On a host without finix's
persistence module that option assignment is simply unused.

## Environment variables (why each exists)

Set by the module and handed to the daemon. The sandbox `env.sh` explains the
crash each NixOS workaround prevents; the module reproduces them:

- `LD_LIBRARY_PATH` = `/run/opengl-driver/lib` + nix-store libstdc++
  (`pkgs.stdenv.cc.cc.lib`) + libz (`pkgs.zlib`). Without libz numpy fails to
  import; without libstdc++ torch/vllm fail. The driver directory is added
  literally (not via `lib.makeLibraryPath`, which would append `/lib`).
- `TRITON_LIBCUDA_PATH` = `/run/opengl-driver/lib`. Triton calls
  `/sbin/ldconfig`, which NixOS does not have.
- `TRITON_PTXAS_PATH`, `TRITON_CUOBJDUMP_PATH`, `TRITON_NVDISASM_PATH` point at
  the CUDA 12.9 binaries from `pkgs.cudaPackages.cuda_nvcc` /
  `cuda_cuobjdump` / `cuda_nvdisasm`. The binaries bundled in the triton wheel
  fail with "cannot execute binary file" here.
- `PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True`.
- `VLLM_WORKER_MULTIPROC_METHOD=spawn` (fork-in-CUDA is unsafe).
- `PYTHONPATH` = the patched store tree (provides the `r2t2` package).
- `ASR_MODEL_PATH`, `VAD_MODEL_PATH`, and the memory knobs below.

## Memory settings (defaults = the measured working point)

Upstream hardcodes `gpu_memory_utilization=0.95`; this box shares one 24 GiB
RTX 4090 with other GPU residents, so that aborts on startup. Defaults:

- `gpuMemoryUtilization = 0.20` (about 4.75 GiB of 24 GiB)
- `maxModelLen = 4096` (`ASR_MAX_MODEL_LEN`)
- `maxNumBatchedTokens = 256` (`ASR_MAX_NUM_BATCHED_TOKENS`, implies
  `max_num_seqs=1`)
- `enforceEager = true` (`ASR_ENFORCE_EAGER=1`)
- `skipMmProfiling = true` (`ASR_SKIP_MM_PROFILING=1`; skips the
  multimodal-encoder profiling run, which OOMs at this free-memory level)

Measured at these defaults from the built artifacts: model load about
3.86 GiB, engine build about 20 s, and the process holds about 5.7 GiB of
VRAM (server ~0.5 GiB + vLLM `EngineCore` ~5.3 GiB).

## Start and stop

Under finit (once enabled and switched):

    initctl status r2t2
    initctl restart r2t2
    initctl stop r2t2
    initctl -v cond get service/r2t2/ready

Readiness: the wrapper starts the server, waits for the socket to accept a
connection (up to 300 s; model load plus engine build is roughly 20 s), then
sends `READY=1` to `$NOTIFY_SOCKET` (`notify:systemd`), which creates
`service/r2t2/ready`. The wrapper runs the server from a writable copy at
`${stateDir}/run/ws_server.py` because `ws_server.py` calls `os.makedirs` on
`logs/` and `wav_tmp_store/` relative to `dirname(__file__)` at import time,
a store path is read-only and the server would crash on import there.

To run it by hand without finit, start the server wrapper directly, exporting
the module's rendered environment (the same vars finit would set). Stop it
only by the PID you recorded, never `pkill`/`pgrep` by name; other agent
sessions share this box.

## Message contract

Unchanged from the sandbox; see
`/home/y0usaf/dev/sandbox/r2t2-20260918/README.md` ("Message contract"). In
brief: a JSON header frame (`secret_key` must be `test0102`), then raw 16 kHz
mono int16 little-endian PCM binary frames, then the EOS text frame
`YOUDAO_ONETIME_ASR_STREAM_EOS`. The server replies with JSON where `msg.text`
is the new segment since the previous message; concatenate client-side.

## Reproducing the streaming output

Command that produced the captured output (own instance on a non-default
port, so the running 8272 server is untouched):

    # with the module's rendered env exported (LD_LIBRARY_PATH, TRITON_*,
    # ASR_MODEL_PATH, VAD_MODEL_PATH, ...):
    .venv/bin/python -u ws_probe.py \
      --uri ws://127.0.0.1:8292/asr_stream_api_v1 \
      --audio <patched-store>/resources/test.wav \
      --language Chinese --save stream-capture.log

Audio: `Confucius4-R2T2/resources/test.wav`, 16000 Hz mono PCM16, 6.740 s,
Chinese speech. Result: text arrives incrementally while the audio is still
streaming; first segment at T+1.691 s, EOS close code 1000, and the segments
concatenate to the same line the sandbox recorded:

    segments = 之前 | 有 | 顾客 | 自己 | 带 | 酒 | 水 | 也没 | 加 | 收 | 钱 | 或者 | 不让 | 喝
    FULL     = 之前有顾客自己带酒水也没加收钱或者不让喝

## The patch

`ws_server-memory-knobs.patch` (in this directory, applied with
`pkgs.applyPatches`) adds `ASR_GPU_MEMORY_UTILIZATION` plus a
`--gpu_memory_utilization` flag, and the `ASR_MAX_MODEL_LEN`,
`ASR_MAX_NUM_BATCHED_TOKENS`, `ASR_ENFORCE_EAGER`, `ASR_SKIP_MM_PROFILING`
knobs. It is carried verbatim from the sandbox; without it the server OOMs on
startup here. Do not silently drop it.

## Caveats

- The marketing claim of a configurable chunk size (80 ms to 2 s) is not
  reachable through this WebSocket server without editing
  `CHUNK_ASR_SECONDS` / `LOOKAHEAD_MS` / `UNFIX_TOKEN_NUM` in `ws_server.py`.
- The server's `secret_key_list` is hardcoded (`test0102` in this build); the
  service is bound to loopback only.
- No quantized checkpoint is used; the 3.9 GiB bf16 weights are the floor.
