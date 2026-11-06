{pkgs, ...}: {
  user.persist.directories = [
    ".config/amp"
    ".local/share/amp"
  ];
  environment.systemPackages = [pkgs.amp-cli];
  environment.variables.AMP_REMOTE_CONTROL_TERMINAL = "1";
}
