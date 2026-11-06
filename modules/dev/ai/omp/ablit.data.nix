# The local refusal-removed model omp-ablit serves, set once here for its server (ablit.nix) and omp's provider
# (box.nix). Picked from the UGI Leaderboard (huggingface.co/spaces/DontPlanToEnd/UGI-Leaderboard, data of
# 2026-10-17): coder3101/gemma-4-31B-it-heretic ranks first by UGI (65.69, W/10 10, NatInt 36.53) of every
# model at 36B parameters or fewer. The imatrix IQ4_XS quant with a q8_0 KV cache of a 32768-token window asks
# the 4090 for 18.9 GiB, which fits beside bolod and the desktop; llama.cpp's --fit spills layers to the CPU
# when another job holds the card, so a busy GPU costs speed, not a failed start. Gemma 4 calls tools natively.
let
  file = "gemma-4-31B-it-heretic.i1-IQ4_XS.gguf";
in {
  port = 8090;
  id = "gemma-4-31b-it-heretic";
  name = "Gemma 4 31B Heretic (local)";
  dir = ".local/share/omp-ablit";
  inherit file;
  url = "https://huggingface.co/mradermacher/gemma-4-31B-it-heretic-i1-GGUF/resolve/main/${file}";
  sha256 = "8a1306ce8f821bb7aa98817fec6d8addfea5eb438769166e2e397708aaebf8a5";
  contextWindow = 32768;
  maxTokens = 16384;
  # omp-ablit's config overlay, placed in the box seed by box.nix: omp runs in the box, which sees only the
  # paths its shares carry, so the overlay rides the seed share like the config omp already reads there.
  overlay = "/mnt/seed/current/ablit.yml";
}
