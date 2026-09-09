# Sourced by the packaged CLI and desktop wrappers. Runtime path only in Nix.
# Keep inherited credentials; missing optional key must not break Codex/OAuth.
if [ -z "${AI_GATEWAY_API_KEY:-}" ] && [ -r "${HERMES_API_KEY_FILE:-}" ]; then
  AI_GATEWAY_API_KEY=$(< "$HERMES_API_KEY_FILE")
  AI_GATEWAY_API_KEY=${AI_GATEWAY_API_KEY%$'\r'}
  if [ -n "$AI_GATEWAY_API_KEY" ]; then
    export AI_GATEWAY_API_KEY
  fi
fi
