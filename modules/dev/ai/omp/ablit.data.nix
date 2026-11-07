# The local refusal-removed model omp-ablit serves, set once here for its server (ablit.nix) and omp's provider
# (box.nix). huihui-ai's abliterated Qwen 3.8 27B, chosen by y0usaf; the UGI Leaderboard has not scored any
# Qwen 3.8 yet. The Unsloth-dynamic Q4_K_M quant (15.4 GiB) with a q8_0 KV cache of a 32768-token window fits
# beside bolod and the desktop; llama.cpp's --fit spills layers to the CPU when another job holds the card, so a
# busy GPU costs speed, not a failed start. Qwen 3.8 calls tools natively.
let
  file = "Huihui-Qwen3.8-27B-abliterated-UD-DW-Q4_K_M.gguf";
in {
  port = 8090;
  id = "qwen3.8-27b-abliterated";
  name = "Qwen 3.8 27B Abliterated (local)";
  dir = ".local/share/omp-ablit";
  inherit file;
  url = "https://huggingface.co/huihui-ai/Huihui-Qwen3.8-27B-abliterated-GGUF/resolve/main/${file}";
  sha256 = "0c7cfe3060493485bb9a6a51195897b0c1d347a49929206adb9a52170183ea03";
  contextWindow = 32768;
  maxTokens = 16384;
  # omp-ablit's config overlay, placed in the box seed by box.nix: omp runs in the box, which sees only the
  # paths its shares carry, so the overlay rides the seed share like the config omp already reads there.
  overlay = "/mnt/seed/current/ablit.yml";
}
