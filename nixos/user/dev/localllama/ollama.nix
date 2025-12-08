{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.dev.localllama = {
    enable = lib.mkEnableOption "Local LLM setup with Ollama";
  };
  config = lib.mkIf config.user.dev.localllama.enable {
    environment.systemPackages = [
      pkgs.ollama
    ];
  };
}
