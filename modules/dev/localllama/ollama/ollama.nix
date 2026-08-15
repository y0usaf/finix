{
  lib,
  ...
}: {
  options.user.dev.localllama = {
    enable = lib.mkEnableOption "Local LLM setup with Ollama";
  };

  # The bridge-era config that enabled services.ollama (a NixOS-only service:
  # enabled + ollama-cuda package + host/port + loadModels + env vars) is
  # DROPPED — finix runs no systemd service for it. The local Ollama provider
  # is reachable by opencode/pi at localhost:11434, but the daemon itself must
  # be run manually (nix shell / systemd user unit) on finix.
}