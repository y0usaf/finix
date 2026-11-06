# The local refusal-removed model omp-ablit serves, set once here for its server (ablit.nix) and omp's provider
# (box.nix). Picked from the UGI Leaderboard (huggingface.co/spaces/DontPlanToEnd/UGI-Leaderboard, data of
# 2026-10-17): coder3101/gemma-4-31B-it-heretic ranks first by UGI (65.69, W/10 10, NatInt 36.53) of every
# model at 36B parameters or fewer. The imatrix IQ4_XS quant leaves room on the RTX 4090 beside bolod for a
# q8_0 KV cache of the whole context window; Gemma 4 has native tool calling.
rec {
  port = 8090;
  id = "gemma-4-31b-it-heretic";
  name = "Gemma 4 31B Heretic (local)";
  dir = ".local/share/omp-ablit";
  file = "gemma-4-31B-it-heretic.i1-IQ4_XS.gguf";
  url = "https://huggingface.co/mradermacher/gemma-4-31B-it-heretic-i1-GGUF/resolve/main/${file}";
  sha256 = "8a1306ce8f821bb7aa98817fec6d8addfea5eb438769166e2e397708aaebf8a5";
  contextWindow = 65536;
  maxTokens = 16384;
  # omp-ablit's config overlay, placed in the box seed by box.nix: omp runs in the box, which sees only the
  # paths its shares carry, so the overlay rides the seed share like the config omp already reads there.
  overlay = "/mnt/seed/current/ablit.yml";
}
