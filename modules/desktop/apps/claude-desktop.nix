# Claude Desktop for Linux (Anthropic's official beta .deb, repackaged).
#
# Upstream ships only an apt repo (downloads.claude.ai/claude-desktop/apt).
# aaddrick/claude-desktop-debian's nix/claude-desktop.nix unpacks that .deb
# and fixes it up with autoPatchelfHook — the vendored Chromium ELF stays,
# so /proc/self/exe resolves inside the store path and resourcesPath is
# correct without an electron swap. callPackage against our pkgs (rather
# than the flake's packages output) keeps a single nixpkgs instance, same
# as codex-desktop.nix.
#
# No enable option by design: modules/desktop is desktop-only (the server's
# domains are core/shell/tools/user-services/dev), so this lands on exactly
# one host.
{
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    (pkgs.callPackage "${flakeInputs.claude-desktop-linux}/nix/claude-desktop.nix" {})
  ];
}
