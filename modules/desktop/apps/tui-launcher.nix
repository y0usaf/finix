{
  lib,
  inputPackages,
  ...
}: {
  environment.systemPackages = [inputPackages.tern-run.default];
  user.defaults.launcher = lib.mkForce "${inputPackages.tern-run.default}/bin/tern-run";
}
