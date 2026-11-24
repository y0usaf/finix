{pkgs, ...}: {
  environment.systemPackages = [(import ../../../pkgs/agent-slack.nix {inherit pkgs;})];
  user.persist.directories = [".config/agent-slack"];
}
