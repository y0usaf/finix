{
  lib,
  inputPackages,
  ...
}: {
  environment.systemPackages = [inputPackages.tern-script.default];
  user.defaults.launcher = lib.mkForce "${inputPackages.tern-script.default}/bin/tern-launcher";
}
