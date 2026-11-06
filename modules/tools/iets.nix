{inputPackages, ...}: {
  environment.systemPackages = [inputPackages.iets.default];
}
