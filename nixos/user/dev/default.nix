_: {
  imports = [
    ./claude-code
    ./codex
    ./opencode/opencode.nix
    ./crush.nix
    ./gemini-cli.nix
    ./agent-slack.nix
    ../../../lib/mcp/mcp.nix

    ./docker.nix
    ./gcloud.nix
    ./latex.nix
    ./bun.nix
    ./localllama/ollama
    ./nvim
    ./python.nix
    ./rust.nix
    ./upscale.nix
    ./android-tools.nix
  ];
}
