{pkgs, ...}: {
  # The same package the box's guest installs, so a boxed bot gets the Slack CLI its own login works with.
  environment.systemPackages = [(import ../../../pkgs/agent-slack.nix {inherit pkgs;})];
}
