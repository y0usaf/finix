{inputPackages, ...}: {
  environment.systemPackages = [inputPackages.swarm.default];
}
