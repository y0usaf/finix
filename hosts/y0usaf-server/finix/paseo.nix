# Paseo daemon on the always-on server: coding-agent orchestration reachable
# from the phone over the tailnet — no hosted relay, no public exposure.
#
# Transport: relay OFF (--no-relay) + direct listen on the server's tailnet
# IP, so all client traffic rides WireGuard. Phone: Paseo app → Add host →
# Direct connection → 100.105.204.116:6767. If the tailnet IP ever changes,
# update listenAddress here (or move to 0.0.0.0 + an nftables rule scoped to
# tailscale0 only).
#
# Agents: claude-code runs as y0usaf (the daemon's user), key injected from
# ~/Tokens/ANTHROPIC_API_KEY.txt via environmentFiles (kept out of the store).
{
  lib,
  ...
}: {
  user.dev = {
    paseo = {
      enable = true;
      relay.enable = false;
      listenAddress = "100.105.204.116"; # server tailnet IP (tailscale ip -4)
      group = "users"; # y0usaf primary group (no y0usaf group on server)
      environmentFiles = [
        "/home/y0usaf/Tokens/ANTHROPIC_API_KEY.txt"
      ];
    };
    claude-code.enable = true;
  };
}
