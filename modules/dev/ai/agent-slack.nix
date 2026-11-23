{pkgs, ...}: {
  environment.systemPackages = [(import ../../../pkgs/agent-slack.nix {inherit pkgs;})];
}
