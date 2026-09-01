{ config, lib, pkgs, ... }:
let
  # Claude Code speaks plain Anthropic protocol; the Vercel AI Gateway exposes
  # the same protocol, so pointing ANTHROPIC_BASE_URL at it is enough.
  gatewayBase = "https://ai-gateway.vercel.sh";
in
{
  options.user.dev.claude-code.enable = lib.mkEnableOption "Claude Code";

  config = lib.mkIf config.user.dev.claude-code.enable {
    environment.systemPackages = [
      pkgs.claude-code
      (pkgs.writeShellScriptBin "claude-vercel" ''
        export ANTHROPIC_BASE_URL="${gatewayBase}"
        export ANTHROPIC_AUTH_TOKEN="''${AI_GATEWAY_API_KEY:?set AI_GATEWAY_API_KEY first}"
        export ANTHROPIC_MODEL="zai/glm-5.3-flash"
        export ANTHROPIC_SMALL_FAST_MODEL="zai/glm-5.3-flash"
        export MAX_THINKING_TOKENS="31999"
        exec ${lib.getExe pkgs.claude-code} --effort ultracode "$@"
      '')
    ];
  };
}
